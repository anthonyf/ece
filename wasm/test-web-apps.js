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
  if (bootstrapJs.includes("ECE_BOOTSTRAP_BUNDLE")) {
    console.log("PASS: ece-bootstrap.js uses ECE_BOOTSTRAP_BUNDLE format");
  } else {
    console.log("FAIL: ece-bootstrap.js missing ECE_BOOTSTRAP_BUNDLE (stale per-space format?)");
    failed++;
  }

  // --- Test 2: Verify sandbox.js uses bundle format ---
  const sandboxJs = fs.readFileSync(path.join(SANDBOX_DIR, "sandbox.js"), "utf8");
  if (sandboxJs.includes("ECE_BOOTSTRAP_BUNDLE") && !sandboxJs.includes("ECE_BOOTSTRAP[")) {
    console.log("PASS: sandbox.js uses ECE_BOOTSTRAP_BUNDLE (not per-space)");
  } else {
    console.log("FAIL: sandbox.js still uses old ECE_BOOTSTRAP[name] format");
    failed++;
  }
  if (sandboxJs.includes("wasm_host: ECE.wasmHost")) {
    console.log("PASS: sandbox.js provides wasm_host imports");
  } else {
    console.log("FAIL: sandbox.js missing wasm_host imports");
    failed++;
  }

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
    console.log("PASS: WASM instantiated with full imports");
  } catch(e) {
    console.log("FAIL: WASM instantiation failed:", e.message);
    failed++;
    process.exit(1);  // can't continue without WASM
  }

  // --- Test 4: Bootstrap loading via bundle ---
  const envHandle = ECE.buildGlobalEnv();
  ECE.globalEnvHandle = envHandle;

  const bootstrapText = fs.readFileSync(path.join(ROOT, "bootstrap", "bootstrap.ecec"), "utf8");
  try {
    ECE.loadArchiveBundle(bootstrapText);
    ECE.wasm.mark_handles();
    console.log("PASS: Bootstrap loaded via loadArchiveBundle");
  } catch(e) {
    console.log("FAIL: Bootstrap loading failed:", e.message);
    failed++;
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
    if (text.includes("Hello, World!")) {
      console.log("PASS: eval-string produced correct output");
    } else {
      console.log("FAIL: eval-string output:", JSON.stringify(text));
      failed++;
    }
  } catch(e) {
    console.log("FAIL: eval-string failed:", e.message);
    failed++;
  }

  // --- Test 6: Pre-compiled program loading (same path as sandbox Run with compiled) ---
  const compiledJs = fs.readFileSync(path.join(SANDBOX_DIR, "ece-compiled.js"), "utf8");
  const match = compiledJs.match(/ECE_COMPILED\["Hello World"\]\s*=\s*"([^"]+)"/);
  if (match) {
    output.length = 0;
    try {
      const ececText = Buffer.from(match[1], "base64").toString("binary");
      const co = ECE.loadArchiveText(ececText);
      ECE.runCodeObject(co);
      const text = output.join("");
      if (text.includes("Hello, World!")) {
        console.log("PASS: Pre-compiled Hello World loaded and ran");
      } else {
        console.log("FAIL: Pre-compiled output:", JSON.stringify(text));
        failed++;
      }
    } catch(e) {
      console.log("FAIL: Pre-compiled loading failed:", e.message);
      failed++;
    }
  } else {
    console.log("FAIL: Could not find ECE_COMPILED[\"Hello World\"] in ece-compiled.js");
    failed++;
  }

  // --- Summary ---
  console.log("");
  if (failed === 0) {
    console.log("Web apps smoke test: 7 passed, 0 failed");
  } else {
    console.log(`Web apps smoke test: ${7 - failed} passed, ${failed} failed`);
    process.exit(1);
  }
}

run().catch(e => {
  console.error("Web apps smoke test error:", e.message);
  process.exit(1);
});
