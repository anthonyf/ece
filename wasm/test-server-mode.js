#!/usr/bin/env node
// ECE Server Mode Integration Test
// Fetches runtime.wasm, bootstrap.ecec, and app.ecec from a local HTTP server,
// boots ECE, runs the app, and verifies output.
// Usage: node wasm/test-server-mode.js <base-url>

const ECE = require("./glue.js");

const baseUrl = process.argv[2];
if (!baseUrl) {
  console.error("Usage: node test-server-mode.js <base-url>");
  process.exit(1);
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
    ffi: ECE.ffi
  };

  const wasmResp = await fetch(`${baseUrl}/runtime.wasm`);
  const wasmBytes = await wasmResp.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
  ECE.wasm = instance.exports;

  // Build global environment
  const envHandle = ECE.buildGlobalEnv();
  ECE.globalEnvHandle = envHandle;

  // Fetch and load bootstrap via archive loader
  const bootResp = await fetch(`${baseUrl}/bootstrap.ecec`);
  const bootText = await bootResp.text();
  ECE.loadArchiveBundleText(bootText);
  ECE.wasm.mark_handles();

  // Fetch and load app via archive loader
  const appResp = await fetch(`${baseUrl}/app.ecec`);
  const appText = await appResp.text();
  ECE.loadArchiveBundleText(appText);

  // Verify output
  const text = output.join("");
  if (text.includes("Hello, World!")) {
    console.log("PASS: Server mode output contains 'Hello, World!'");
    console.log("Output:", JSON.stringify(text.trim()));
    process.exit(0);
  } else {
    console.log("FAIL: Expected 'Hello, World!' in output");
    console.log("Got:", JSON.stringify(text));
    process.exit(1);
  }
}

run().catch(e => {
  console.error("Server mode test error:", e.message);
  process.exit(1);
});
