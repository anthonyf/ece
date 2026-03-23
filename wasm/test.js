#!/usr/bin/env node
// ECE WASM Test Runner
// Loads the WASM runtime, boots bootstrap, runs compiled tests, reports results.
// Usage: node wasm/test.js [path-to-test.ecec]

const ECE = require("./glue.js");
const fs = require("fs");
const path = require("path");

const testFile = process.argv[2] || path.join(__dirname, "..", "wasm-tests.ecec");
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
    canvas: ECE.canvas,
    timing: ECE.timing,
    math: ECE.math,
    ffi: ECE.ffi
  };

  const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
  ECE.wasm = instance.exports;
  const w = ECE.wasm;

  // Build global environment
  const envH = ECE.buildGlobalEnv();

  // Boot bootstrap files via WAT-native .ecec reader
  const bootFiles = ["prelude", "compiler", "reader", "assembler", "compilation-unit"];
  for (const name of bootFiles) {
    const text = fs.readFileSync(path.join(bootstrapDir, name + ".ecec"), "utf-8");
    const spaceId = ECE.loadEcecText(text);
    w.run(spaceId, 0, envH);
    console.log(`Loaded space "${name}"`);
  }

  // Load and run tests
  if (!fs.existsSync(testFile)) {
    console.error("Test file not found:", testFile);
    process.exit(1);
  }

  const testText = fs.readFileSync(testFile, "utf-8");
  const testSpaceId = ECE.loadEcecText(testText);

  const t0 = Date.now();
  try {
    w.run(testSpaceId, 0, envH);
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
