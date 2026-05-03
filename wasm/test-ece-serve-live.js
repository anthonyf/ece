#!/usr/bin/env node
// ECE Serve Live Reload Smoke Test
// Starts bin/ece-serve, verifies sandbox dev URL injection, connects to the
// WebSocket endpoint, edits the watched source, and expects a program-reload
// artifact broadcast.

const childProcess = require("child_process");
const crypto = require("crypto");
const fs = require("fs/promises");
const net = require("net");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const WORK_DIR = path.join(ROOT, ".tmp", "ece-serve-live-test");
const ENTRY = path.join(WORK_DIR, "live.scm");
const SERVER = path.join(ROOT, "bin", "ece-serve");
const WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function withTimeout(promise, ms, label) {
  let timer;
  const timeout = new Promise((_resolve, reject) => {
    timer = setTimeout(() => reject(new Error(`Timed out waiting for ${label}`)), ms);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

async function freePort() {
  const server = net.createServer();
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const port = server.address().port;
  await new Promise(resolve => server.close(resolve));
  return port;
}

async function waitForHttp(port) {
  const url = `http://127.0.0.1:${port}/`;
  const deadline = Date.now() + 10000;
  let lastError;

  while (Date.now() < deadline) {
    try {
      const response = await fetch(url);
      if (response.ok) return response;
      lastError = new Error(`HTTP ${response.status}`);
    } catch (err) {
      lastError = err;
    }
    await delay(100);
  }

  throw new Error(`ece-serve did not become ready: ${lastError ? lastError.message : "no response"}`);
}

function expectedWebSocketAccept(key) {
  return crypto.createHash("sha1").update(key + WS_GUID).digest("base64");
}

function connectDevWebSocket(port, token) {
  const socket = net.createConnection({ host: "127.0.0.1", port });
  let buffer = Buffer.alloc(0);

  socket.on("data", chunk => {
    buffer = Buffer.concat([buffer, chunk]);
  });

  function waitUntil(consume, label) {
    return new Promise((resolve, reject) => {
      const onData = () => check();
      const onError = err => cleanup(() => reject(err));
      const onClose = () => cleanup(() => reject(new Error(`${label} closed before completing`)));
      const cleanup = done => {
        socket.off("data", onData);
        socket.off("error", onError);
        socket.off("close", onClose);
        done();
      };
      const check = () => {
        try {
          const value = consume();
          if (value !== undefined) cleanup(() => resolve(value));
        } catch (err) {
          cleanup(() => reject(err));
        }
      };

      socket.on("data", onData);
      socket.once("error", onError);
      socket.once("close", onClose);
      check();
    });
  }

  function consumeHttpHeader() {
    const idx = buffer.indexOf("\r\n\r\n");
    if (idx < 0) return undefined;
    const header = buffer.subarray(0, idx + 4).toString("latin1");
    buffer = buffer.subarray(idx + 4);
    return header;
  }

  function consumeTextFrame() {
    if (buffer.length < 2) return undefined;

    const first = buffer[0];
    const second = buffer[1];
    const opcode = first & 0x0f;
    const masked = (second & 0x80) !== 0;
    let len = second & 0x7f;
    let offset = 2;

    if (len === 126) {
      if (buffer.length < 4) return undefined;
      len = buffer.readUInt16BE(2);
      offset = 4;
    } else if (len === 127) {
      if (buffer.length < 10) return undefined;
      const bigLen = buffer.readBigUInt64BE(2);
      if (bigLen > BigInt(Number.MAX_SAFE_INTEGER)) {
        throw new Error("WebSocket frame is too large for this smoke test");
      }
      len = Number(bigLen);
      offset = 10;
    }

    if (masked) throw new Error("server sent a masked WebSocket frame");
    if (buffer.length < offset + len) return undefined;

    const payload = buffer.subarray(offset, offset + len);
    buffer = buffer.subarray(offset + len);
    if (opcode === 1) return payload.toString("utf8");
    if (opcode === 8) throw new Error("server closed WebSocket before expected message");
    return undefined;
  }

  const key = crypto.randomBytes(16).toString("base64");
  const request = [
    `GET /ws?token=${token} HTTP/1.1`,
    `Host: 127.0.0.1:${port}`,
    "Upgrade: websocket",
    "Connection: Upgrade",
    `Sec-WebSocket-Key: ${key}`,
    "Sec-WebSocket-Version: 13",
    "",
    ""
  ].join("\r\n");

  return new Promise((resolve, reject) => {
    socket.once("error", reject);
    socket.once("connect", () => {
      socket.off("error", reject);
      socket.write(request);
      withTimeout(waitUntil(consumeHttpHeader, "WebSocket handshake"), 5000, "WebSocket handshake")
        .then(header => {
          if (!header.startsWith("HTTP/1.1 101")) {
            throw new Error(`WebSocket upgrade failed: ${header.split("\r\n")[0]}`);
          }
          const acceptLine = header.split("\r\n").find(line =>
            line.toLowerCase().startsWith("sec-websocket-accept:"));
          const accept = acceptLine ? acceptLine.split(":").slice(1).join(":").trim() : "";
          if (accept !== expectedWebSocketAccept(key)) {
            throw new Error("WebSocket upgrade returned an invalid Sec-WebSocket-Accept");
          }
          resolve({
            nextTextFrame: () => waitUntil(consumeTextFrame, "WebSocket text frame"),
            close: () => socket.destroy()
          });
        })
        .catch(err => {
          socket.destroy();
          reject(err);
        });
    });
  });
}

async function stopServer(server) {
  if (!server || server.exitCode !== null || server.signalCode !== null) return;

  const exited = new Promise(resolve => server.once("exit", resolve));
  server.kill("SIGTERM");
  try {
    await withTimeout(exited, 3000, "ece-serve exit");
  } catch (_err) {
    const killed = new Promise(resolve => server.once("exit", resolve));
    server.kill("SIGKILL");
    await killed;
  }
}

function serverExitBeforeReady(server) {
  return new Promise((_resolve, reject) => {
    server.once("error", err => {
      reject(new Error(`ece-serve failed to start: ${err.message}`));
    });
    server.once("exit", (code, signal) => {
      reject(new Error(`ece-serve exited before becoming ready (${signal || code})`));
    });
  });
}

async function runAttempt() {
  await fs.writeFile(ENTRY, "(define live-marker 1)\n", "utf8");

  const port = await freePort();
  const devToken = "smoke-token";
  const server = childProcess.spawn(
    SERVER,
    [ENTRY, "--port", String(port), "--poll-interval", "50", "--dev-token", devToken],
    { cwd: ROOT, stdio: ["ignore", "pipe", "pipe"] });
  let serverOutput = "";
  server.stdout.on("data", chunk => { serverOutput += chunk.toString(); });
  server.stderr.on("data", chunk => { serverOutput += chunk.toString(); });

  let wsClient;
  let ready = false;
  try {
    const response = await Promise.race([waitForHttp(port), serverExitBeforeReady(server)]);
    ready = true;
    const html = await response.text();
    const expectedWsUrl = `ws://127.0.0.1:${port}/ws?token=${devToken}`;

    if (!html.includes(`window.ECE_DEV_WS_URL = "${expectedWsUrl}";`)) {
      throw new Error("sandbox index did not include the injected dev WebSocket URL");
    }
    if (!String(response.headers.get("cache-control") || "").includes("no-store")) {
      throw new Error("sandbox index response did not disable caching");
    }

    wsClient = await connectDevWebSocket(port, devToken);

    const evalMessage = withTimeout(
      wsClient.nextTextFrame(),
      7000,
      "eval-source");

    const evalResponse = await fetch(`http://127.0.0.1:${port}/__ece_dev/eval-source`, {
      method: "POST",
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "X-ECE-Dev-Token": devToken,
        "X-ECE-Path": "editor-buffer.scm"
      },
      body: "(define editor-live-marker 41)\n(+ editor-live-marker 1)\n"
    });
    if (!evalResponse.ok) {
      throw new Error(`editor eval-source POST failed: HTTP ${evalResponse.status}`);
    }

    const evalRaw = await evalMessage;
    const evalUpdate = JSON.parse(evalRaw);
    if (evalUpdate.type !== "eval-source") {
      throw new Error(`expected eval-source, got ${evalUpdate.type}`);
    }
    if (evalUpdate.path !== "editor-buffer.scm") {
      throw new Error(`eval-source path mismatch: ${evalUpdate.path}`);
    }
    if (!String(evalUpdate.source || "").includes("editor-live-marker")) {
      throw new Error("eval-source did not include posted source");
    }

    const programReloadMessage = withTimeout(
      wsClient.nextTextFrame(),
      7000,
      "program-reload");

    const programReloadResponse = await fetch(`http://127.0.0.1:${port}/__ece_dev/program-reload`, {
      method: "POST",
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "X-ECE-Dev-Token": devToken,
        "X-ECE-Zone-Module-Url": "/app-zones.wasm",
        "X-ECE-Manifest-Url": "/app-zones.manifest"
      },
      body: "/app.ecec"
    });
    if (!programReloadResponse.ok) {
      throw new Error(`editor program-reload POST failed: HTTP ${programReloadResponse.status}`);
    }

    const programReloadRaw = await programReloadMessage;
    const programReload = JSON.parse(programReloadRaw);
    if (programReload.type !== "program-reload") {
      throw new Error(`expected program-reload, got ${programReload.type}`);
    }
    if (programReload.archiveUrl !== "/app.ecec") {
      throw new Error(`program-reload archiveUrl mismatch: ${programReload.archiveUrl}`);
    }
    if (programReload.zoneModuleUrl !== "/app-zones.wasm") {
      throw new Error(`program-reload zoneModuleUrl mismatch: ${programReload.zoneModuleUrl}`);
    }
    if (programReload.manifestUrl !== "/app-zones.manifest") {
      throw new Error(`program-reload manifestUrl mismatch: ${programReload.manifestUrl}`);
    }

    const watchedReloadMessage = withTimeout(
      wsClient.nextTextFrame(),
      7000,
      "watched program-reload");

    // CL file-write-date commonly has one-second granularity. Give the
    // watcher baseline a distinct timestamp before rewriting the source.
    await delay(1200);
    await fs.writeFile(ENTRY, "(define live-marker 2)\n(display live-marker)\n", "utf8");

    const raw = await watchedReloadMessage;
    const message = JSON.parse(raw);
    if (message.type !== "program-reload") {
      throw new Error(`expected watched program-reload, got ${message.type}`);
    }
    if (message.archiveUrl !== "/__ece_dev/artifacts/app.ecec") {
      throw new Error(`watched program-reload archiveUrl mismatch: ${message.archiveUrl}`);
    }
    if (message.zoneModuleUrl !== null || message.manifestUrl !== null) {
      throw new Error("watched program-reload should be archive-only");
    }

    const artifactResp = await fetch(`http://127.0.0.1:${port}${message.archiveUrl}`);
    if (!artifactResp.ok) {
      throw new Error(`dev artifact fetch failed: HTTP ${artifactResp.status}`);
    }
    const artifactText = await artifactResp.text();
    if (!artifactText.includes(":ecec-archive") || !artifactText.includes("live.scm")) {
      throw new Error("dev artifact did not look like a compiled live.scm archive");
    }

    console.log("PASS: ece-serve injected the dev WebSocket URL");
    console.log("PASS: ece-serve relayed an editor eval-source command");
    console.log("PASS: ece-serve relayed an editor program-reload command");
    console.log("PASS: ece-serve built and broadcast a program-reload artifact for a watched edit");
    console.log("ece-serve live reload smoke test: 4 passed, 0 failed");
  } catch (err) {
    err.serverOutput = serverOutput;
    err.retryable = !ready;
    throw err;
  } finally {
    if (wsClient) wsClient.close();
    await stopServer(server);
  }
}

async function run() {
  if (typeof fetch !== "function") {
    throw new Error("Node fetch is required for this smoke test");
  }

  await fs.rm(WORK_DIR, { recursive: true, force: true });
  await fs.mkdir(WORK_DIR, { recursive: true });

  const maxAttempts = 3;
  let lastError;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await runAttempt();
      return;
    } catch (err) {
      lastError = err;
      if (!err.retryable || attempt === maxAttempts) break;
      await delay(100);
    }
  }

  if (lastError && lastError.serverOutput && lastError.serverOutput.trim()) {
    console.error("ece-serve output:");
    console.error(lastError.serverOutput.trim());
  }
  throw lastError;
}

run().catch(err => {
  console.error("ece-serve live reload smoke test failed:", err.message);
  process.exit(1);
});
