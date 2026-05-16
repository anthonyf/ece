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
    sandboxJs.includes("ECE.loadArchiveBundleBase64(ECE_BOOTSTRAP_BUNDLE)") &&
      !sandboxJs.includes("atob(ECE_BOOTSTRAP_BUNDLE)"),
    "sandbox.js boots bootstrap via archive auto-detection",
    "sandbox.js decodes bootstrap as text instead of using archive auto-detection");
  check(
    sandboxJs.includes("compile-file->archive-result") &&
      sandboxJs.includes("ECE._storeSet(filename, source)") &&
      !sandboxJs.includes("ECE_COMPILED") &&
      !sandboxJs.includes("loadArchiveBase64(progData)"),
    "sandbox Run compiles editor source instead of loading precompiled demos",
    "sandbox Run still uses precompiled demo archives instead of editor source");
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
  check(
    !sandboxHtml.includes("ece-compiled.js"),
    "sandbox index does not load precompiled demo archives",
    "sandbox index still loads ece-compiled.js");

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

  const canvasDemos = [
    "game-loop.scm",
    "sierpinski-triangle.scm",
    "starfield.scm",
    "analog-clock.scm",
    "mandelbrot.scm",
    "plasma.scm"
  ];
  function hasFormContaining(source, head, bodyPattern) {
    const compact = source.replace(/\s+/g, " ");
    const index = compact.indexOf(head);
    if (index < 0) return false;
    const end = compact.indexOf(")", index);
    return end >= 0 && bodyPattern.test(compact.slice(index, end + 1));
  }
  check(
    canvasDemos.every((file) => {
      const source = fs.readFileSync(path.join(SANDBOX_DIR, "programs", file), "utf8");
      return /\(define-module\s+\(sandbox\s+/.test(source) &&
        hasFormContaining(source, "(import", /\(ece browser canvas\)/) &&
        hasFormContaining(source, "(export", /\bstart\b/) &&
        source.includes("(start)");
    }),
    "canvas sandbox demos import the browser canvas module",
    "one or more canvas sandbox demos still use unscoped global canvas code");
  const clockSource = fs.readFileSync(path.join(SANDBOX_DIR, "programs", "analog-clock.scm"), "utf8");
  check(
    clockSource.includes("(total-seconds (quotient ms 1000))") &&
      clockSource.includes("(ma (- (* (+ minute (/ second 60)) pi-over-30) pi-over-2))") &&
      clockSource.includes("(ha (- (* (+ hour (/ minute 60)) pi-over-6) pi-over-2))") &&
      !clockSource.includes("sec-frac") &&
      !clockSource.includes("min-frac") &&
      !clockSource.includes("hr-frac"),
    "analog clock derives hand angles from wall-clock components",
    "analog clock still drives hands directly from raw millisecond fractions");

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

  const bootstrapBytes = fs.readFileSync(path.join(ROOT, "bootstrap", "bootstrap.ecec"));
  try {
    ECE.loadArchiveBundleAuto(bootstrapBytes);
    ECE.wasm.mark_handles();
    check(true, "Bootstrap loaded via loadArchiveBundleAuto", "Bootstrap loading failed");
  } catch(e) {
    check(false, "Bootstrap loaded via loadArchiveBundleAuto", `Bootstrap loading failed: ${e.message}`);
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

  function compileAndRunSource(source, filename) {
    ECE.wasm.reset_handles();
    ECE._refreshSingletonHandles();
    ECE._symCache = {};
    ECE._storeSet(filename, source);
    const co = ECE.evalStringLast(
      `(car (compile-file->archive-result ${ECE._schemeStringLiteral(filename)}))`);
    return ECE.runCodeObject(co);
  }

  // --- Test 7: Sandbox Run compiles and runs editor source ---
  output.length = 0;
  try {
    compileAndRunSource('(display "Hello, World!")(newline)', "__sandbox_test__/hello.scm");
    const text = output.join("");
    check(
      text.includes("Hello, World!"),
      "sandbox source compile path runs plain editor source",
      `sandbox source compile output: ${JSON.stringify(text)}`);
  } catch(e) {
    check(false, "sandbox source compile path runs plain editor source", `sandbox source compile failed: ${e.message}`);
  }

  // --- Test 8: Module-shaped demos use the same source compile path ---
  const originalDocument = globalThis.document;
  try {
    const canvasContext = {
      canvas: { width: 640, height: 480 },
      clearRect() {},
      fillRect() {},
      beginPath() {},
      arc() {},
      fill() {},
      fillText() {},
      set fillStyle(_value) {},
      set font(_value) {}
    };
    globalThis.document = {
      getElementById() {
        return { getContext() { return canvasContext; } };
      }
    };
    const sierpinskiSource = fs.readFileSync(path.join(SANDBOX_DIR, "programs", "sierpinski-triangle.scm"), "utf8");
    compileAndRunSource(sierpinskiSource, "__sandbox_test__/sierpinski-triangle.scm");
    ECE.wasm.clear_yield_cont();
    ECE.wasm.set_yield_flag(0);
    check(
      true,
      "sandbox source compile path runs module-shaped demos",
      "sandbox source compile module path failed");
  } catch(e) {
    check(false, "sandbox source compile path runs module-shaped demos", `sandbox source compile module failed: ${e.message}`);
  } finally {
    globalThis.document = originalDocument;
  }

  // --- Test 9: Edited module text is what runs ---
  output.length = 0;
  try {
    compileAndRunSource(
      "(define-module (sandbox edited-run-probe)\n" +
        "  (export start)\n" +
        "  (define (start) (display \"edited source ran\") (newline))\n" +
        "  (start))\n",
      "__sandbox_test__/edited-run-probe.scm");
    const text = output.join("");
    check(
      text.includes("edited source ran"),
      "sandbox source compile path honors edited module text",
      `edited module output: ${JSON.stringify(text)}`);
  } catch(e) {
    check(false, "sandbox source compile path honors edited module text", `edited module source compile failed: ${e.message}`);
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
