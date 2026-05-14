#!/usr/bin/env node
// ECE Server Mode Integration Test
// Fetches runtime.wasm, bootstrap.ecec, and app.ecec from a local HTTP server,
// boots ECE, runs the app, and verifies output.
// Usage: node wasm/test-server-mode.js <base-url>

const ECE = require("./glue.js");

const baseUrl = process.argv[2];
if (!baseUrl) {
  console.error("Usage: node test-server-mode.js <base-url> [expected-text]");
  process.exit(1);
}
const expectedText = process.argv[3] || "Hello, World!";

async function tryLoadNativeZones(ECE, envHandle, baseUrl) {
  let manifestResp;
  let wasmResp;

  try {
    manifestResp = await fetch(`${baseUrl}/app-zones.manifest`);
    wasmResp = await fetch(`${baseUrl}/app-zones.wasm`);
  } catch (_err) {
    return;
  }
  if (!manifestResp.ok || !wasmResp.ok) return;

  ECE.wasmHost.setText("app-zones.manifest", await manifestResp.text());
  ECE.wasmHost.setBytes("app-zones.wasm", await wasmResp.arrayBuffer());
  const evalStr = ECE.wasm.env_lookup(envHandle, ECE.internSym("eval-string-last"));
  ECE.wasm.call_ece_proc(
    evalStr,
    ECE.wasm.h_cons(
      ECE.makeString("(load-native-zone-module \"app-zones.wasm\" \"app-zones.manifest\")"),
      ECE.wasm.h_nil()));
}

async function run() {
  const output = [];

  // Override I/O to capture output
  ECE.io.display_string = function(len) {
    const mem = new Uint16Array(ECE.wasm.memory.buffer, 0, len);
    output.push(String.fromCharCode(...mem));
  };
  ECE.io.display_number = function(n) { output.push(String(n)); };
  ECE.io.newline = function() { output.push("\n"); };
  ECE.io.runtime_error = function(len) {
    const mem = new Uint16Array(ECE.wasm.memory.buffer, 0, len);
    throw new Error(String.fromCharCode(...mem));
  };

  // Fetch and instantiate WASM
  const imports = {
    io: ECE.io,
    loader: ECE.loader,
    storage: ECE.storage,
    canvas: ECE.canvas,
    timing: ECE.timing,
    math: ECE.math,
    ffi: ECE.ffi,
    wasm_host: ECE.wasmHost
  };

  const wasmResp = await fetch(`${baseUrl}/runtime.wasm`);
  const wasmBytes = await wasmResp.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
  ECE.wasm = instance.exports;

  // Build global environment
  const envHandle = ECE.buildGlobalEnv();
  ECE.globalEnvHandle = envHandle;

  // Fetch and load bootstrap via archive loader (multi-archive bundle)
  await ECE.fetchAndLoadArchiveBundle(`${baseUrl}/bootstrap.ecec`);
  ECE.wasm.mark_handles();

  await tryLoadNativeZones(ECE, envHandle, baseUrl);

  // Fetch and load app via archive loader
  await ECE.fetchAndLoadArchiveBundle(`${baseUrl}/app.ecec`);

  // Verify output
  const text = output.join("");
  if (text.includes(expectedText)) {
    console.log(`PASS: Server mode output contains '${expectedText}'`);
    console.log("Output:", JSON.stringify(text.trim()));
    process.exit(0);
  } else {
    console.log(`FAIL: Expected '${expectedText}' in output`);
    console.log("Got:", JSON.stringify(text));
    process.exit(1);
  }
}

run().catch(e => {
  console.error("Server mode test error:", e.message);
  process.exit(1);
});
