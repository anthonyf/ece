#!/usr/bin/env node
// ECE WASM Test Runner
// Loads the WASM runtime, boots bootstrap, runs compiled tests, reports results.
// Usage: node wasm/test.js [path-to-test.ececb]

const ECE = require("./glue.js");
const fs = require("fs");
const path = require("path");

const testFile = process.argv[2] || path.join(__dirname, "..", "wasm-tests.ececb");
const bootstrapDir = path.join(__dirname, "..", "bootstrap");
const wasmFile = path.join(__dirname, "runtime.wasm");

async function run() {
  // Load WASM module
  const wasmBytes = fs.readFileSync(wasmFile);
  const output = [];
  const imports = {
    io: {
      display_string(len) {
        const mem = new Uint16Array(ECE.wasm.memory.buffer, 0, len);
        output.push(String.fromCharCode(...mem));
      },
      display_number(n) { output.push(String(n)); },
      newline() { output.push("\n"); },
      trace_pc() {}
    },
    loader: { fetch_ececb() { return null; } },
    storage: ECE.storage,
    canvas: ECE.canvas
  };

  const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
  ECE.wasm = instance.exports;
  const w = ECE.wasm;

  // Build global environment
  const envH = ECE.buildGlobalEnv();

  // Boot bootstrap files
  const bootFiles = ["prelude", "compiler", "reader", "assembler", "compilation-unit"];
  for (const name of bootFiles) {
    const bytes = new Uint8Array(fs.readFileSync(path.join(bootstrapDir, name + ".ececb")));
    const parsed = ECE.parseBinary(bytes);
    ECE.loadParsed(parsed);
    w.run(w.sym_id(ECE.internSym(parsed.spaceName)), 0, envH);
  }

  // Load and run tests
  if (!fs.existsSync(testFile)) {
    console.error("Test file not found:", testFile);
    process.exit(1);
  }

  const testBytes = new Uint8Array(fs.readFileSync(testFile));
  const testParsed = ECE.parseBinary(testBytes);
  ECE.loadParsed(testParsed);

  const t0 = Date.now();
  try {
    w.run(w.sym_id(ECE.internSym(testParsed.spaceName)), 0, envH);
  } catch (e) {
    // Some tests may crash — continue to parse output
  }
  const elapsed = Date.now() - t0;

  // Parse output for results
  const text = output.join("");
  const lines = text.split("\n");

  // Print test output
  for (const line of lines) {
    if (line.includes("FAIL") || line.includes("passed,") || line.startsWith("Running")) {
      console.log(line);
    }
  }

  // Find pass/fail counts
  let passed = 0, failed = 0;
  for (const line of lines) {
    const match = line.match(/(\d+) passed, (\d+) failed/);
    if (match) {
      passed = parseInt(match[1]);
      failed = parseInt(match[2]);
    }
  }

  console.log(`\nWASM tests: ${passed} passed, ${failed} failed (${elapsed}ms)`);

  if (failed > 0 || passed === 0) {
    process.exit(1);
  }
}

run().catch(e => {
  console.error("WASM test runner error:", e.message);
  process.exit(1);
});
