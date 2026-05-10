#!/usr/bin/env node
// ECE Web Apps Smoke Test
// Validates that the sandbox and test page boot sequence works:
// WASM instantiation with full imports, bootstrap loading via bundle,
// and eval-string execution. Catches import mismatches and stale bootstrap formats.
// Usage: node wasm/test-web-apps.js

const fs = require("fs");
const path = require("path");
const ECE = require("./glue.js");

const ROOT = path.resolve(__dirname, "..");
const SANDBOX_DIR = path.join(ROOT, "sandbox");

async function run() {
  const output = [];
  let failed = 0;
  let total = 0;

  function check(condition, passMessage, failMessage) {
    total++;
    if (condition) {
      console.log(`PASS: ${passMessage}`);
    } else {
      console.log(`FAIL: ${failMessage}`);
      failed++;
    }
  }

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

  // --- Test 1: Verify sandbox ece-bootstrap.js uses bundle format ---
  const bootstrapJs = fs.readFileSync(path.join(SANDBOX_DIR, "ece-bootstrap.js"), "utf8");
  check(
    bootstrapJs.includes("ECE_BOOTSTRAP_BUNDLE"),
    "ece-bootstrap.js uses ECE_BOOTSTRAP_BUNDLE format",
    "ece-bootstrap.js missing ECE_BOOTSTRAP_BUNDLE (stale per-space format?)");

  // --- Test 2: Verify sandbox.js uses bundle format ---
  const sandboxJs = fs.readFileSync(path.join(SANDBOX_DIR, "sandbox.js"), "utf8");
  check(
    sandboxJs.includes("ECE_BOOTSTRAP_BUNDLE") && !sandboxJs.includes("ECE_BOOTSTRAP["),
    "sandbox.js uses ECE_BOOTSTRAP_BUNDLE (not per-space)",
    "sandbox.js still uses old ECE_BOOTSTRAP[name] format");
  check(
    sandboxJs.includes("wasm_host: ECE.wasmHost"),
    "sandbox.js provides wasm_host imports",
    "sandbox.js missing wasm_host imports");
  check(
    sandboxJs.includes("connectDevServer") &&
      sandboxJs.includes("browser-dev-client-handle-source-update") &&
      sandboxJs.includes("applyDevServerProgramReload") &&
      sandboxJs.includes("reloadProgramFromUrls"),
    "sandbox.js has thin dev-server WebSocket bridge",
    "sandbox.js missing dev-server WebSocket bridge");

  const sandboxHtml = fs.readFileSync(path.join(SANDBOX_DIR, "index.html"), "utf8");
  check(
    sandboxHtml.includes("window.ECE_DEV_WS_URL = null;"),
    "sandbox index has dev-server URL injection point",
    "sandbox index missing dev-server URL injection point");

  const webAppIndex = fs.readFileSync(path.join(ROOT, "templates", "web-app", "index.html"), "utf8");
  check(
    /<div\b[^>]*\bid=["']app-root["'][^>]*>/i.test(webAppIndex) &&
      /<pre\b[^>]*\bid=["']output["'][^>]*>/i.test(webAppIndex),
    "web-app template keeps host roots in index.html",
    "web-app template missing app/output roots");
  check(
    !webAppIndex.includes("app-shell") &&
      !webAppIndex.includes("sandbox-canvas") &&
      !/<style\b/i.test(webAppIndex),
    "web-app index leaves app shell rendering to ECE",
    "web-app index still contains app shell HTML/CSS");

  const webAppMain = fs.readFileSync(path.join(ROOT, "templates", "web-app", "main.scm"), "utf8");
  check(
    webAppMain.includes("(define-module (app main)") &&
      webAppMain.includes("(import (ece browser dom)") &&
      webAppMain.includes("(ece browser html)") &&
      webAppMain.includes("(export start tick)") &&
      webAppMain.includes("(start)"),
    "web-app main renders from an ECE app module",
    "web-app main is not module-shaped ECE rendering code");

  // --- Test 3: WASM instantiation with full imports ---
  const wasmBytes = fs.readFileSync(path.join(ROOT, "wasm", "runtime.wasm"));
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

  try {
    const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
    ECE.wasm = instance.exports;
    check(true, "WASM instantiated with full imports", "WASM instantiation failed");
  } catch(e) {
    check(false, "WASM instantiated with full imports", `WASM instantiation failed: ${e.message}`);
    process.exit(1);  // can't continue without WASM
  }

  // --- Test 4: Bootstrap loading via bundle ---
  const envHandle = ECE.buildGlobalEnv();
  ECE.globalEnvHandle = envHandle;

  const bootstrapText = fs.readFileSync(path.join(ROOT, "bootstrap", "bootstrap.ecec"), "utf8");
  try {
    ECE.loadArchiveBundle(bootstrapText);
    ECE.wasm.mark_handles();
    check(true, "Bootstrap loaded via loadArchiveBundle", "Bootstrap loading failed");
  } catch(e) {
    check(false, "Bootstrap loaded via loadArchiveBundle", `Bootstrap loading failed: ${e.message}`);
    process.exit(1);  // can't continue without bootstrap
  }

  // --- Test 5: eval-string works (same path as sandbox Run button) ---
  output.length = 0;
  try {
    const w = ECE.wasm;
    const evalStrProc = w.env_lookup(envHandle, ECE.internSym("eval-string"));
    if (!evalStrProc) throw new Error("eval-string not found in environment");
    w.call_ece_proc(evalStrProc, w.h_cons(ECE.makeString('(display "Hello, World!")(newline)'), ECE._hNil));
    const text = output.join("");
    check(
      text.includes("Hello, World!"),
      "eval-string produced correct output",
      `eval-string output: ${JSON.stringify(text)}`);
  } catch(e) {
    check(false, "eval-string produced correct output", `eval-string failed: ${e.message}`);
  }

  // --- Test 6: browser dev-client source update policy lives in ECE ---
  try {
    const result = ECE.evalStringLast(
      '(browser-dev-client-handle-source-update "probe.scm" "(define *dev-client-probe* 41) (+ *dev-client-probe* 1)")');
    const text = ECE._eceToJs(result);
    check(
      text.includes(";; source updated: probe.scm") && text.includes("42"),
      "browser dev-client handles source updates in ECE",
      `browser dev-client result: ${JSON.stringify(text)}`);
  } catch(e) {
    check(false, "browser dev-client handles source updates in ECE", `browser dev-client source update failed: ${e.message}`);
  }

  // --- Test 7: Pre-compiled program loading (same path as sandbox Run with compiled) ---
  const compiledJs = fs.readFileSync(path.join(SANDBOX_DIR, "ece-compiled.js"), "utf8");
  const match = compiledJs.match(/ECE_COMPILED\["Hello World"\]\s*=\s*"([^"]+)"/);
  if (match) {
    output.length = 0;
    try {
      const ececText = Buffer.from(match[1], "base64").toString("binary");
      const co = ECE.loadArchiveText(ececText);
      ECE.runCodeObject(co);
      const text = output.join("");
      check(
        text.includes("Hello, World!"),
        "Pre-compiled Hello World loaded and ran",
        `Pre-compiled output: ${JSON.stringify(text)}`);
    } catch(e) {
      check(false, "Pre-compiled Hello World loaded and ran", `Pre-compiled loading failed: ${e.message}`);
    }
  } else {
    check(false, "Pre-compiled Hello World loaded and ran", "Could not find ECE_COMPILED[\"Hello World\"] in ece-compiled.js");
  }

  // --- Summary ---
  console.log("");
  if (failed === 0) {
    console.log(`Web apps smoke test: ${total} passed, 0 failed`);
  } else {
    console.log(`Web apps smoke test: ${total - failed} passed, ${failed} failed`);
    process.exit(1);
  }
}

run().catch(e => {
  console.error("Web apps smoke test error:", e.message);
  process.exit(1);
});
