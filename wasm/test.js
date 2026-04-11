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

// ── Integration tests (JS↔WASM boundary) ──

function runIntegrationTests(w, envH, output) {
  let iPassed = 0, iFailed = 0;

  function iTest(name, fn) {
    try {
      fn();
      iPassed++;
    } catch (e) {
      console.log(`  FAIL: ${name}: ${e.message}`);
      iFailed++;
    }
  }

  function assert(cond, msg) {
    if (!cond) throw new Error(msg || "assertion failed");
  }

  // ── Op-id exhaustive check (canonical IDs from operations.def) ──
  const opNames = [
    'lookup-variable-value', 'lookup-global-variable',
    'set-variable-value!', 'define-variable!', 'extend-environment',
    'lexical-ref', 'lexical-set!',
    'make-compiled-procedure', 'compiled-procedure-entry', 'compiled-procedure-env',
    'primitive-procedure?', 'continuation?', 'parameter?',
    'apply-primitive-procedure', 'apply-parameter',
    'parameter-ref', 'parameter-set!', 'parameter-raw-set!',
    'capture-continuation', 'do-continuation-winds',
    'continuation-stack', 'continuation-conts',
    'false?',
    'list', 'cons', 'car', 'cdr'
  ];
  for (let i = 0; i < opNames.length; i++) {
    iTest(`op-id ${opNames[i]} = ${i}`, () => {
      const sym = ECE.internSym(opNames[i]);
      const id = w.check_op_id(sym);
      assert(id === i, `expected ${i}, got ${id}`);
    });
  }

  // ── Validate bootstrap spaces ──
  const bootNames = ["prelude", "compiler", "reader", "assembler", "compilation-unit"];
  for (const name of bootNames) {
    iTest(`validate space "${name}"`, () => {
      const sym = ECE.internSym(name);
      const spaceId = w.sym_id(sym);
      const result = w.validate_space(spaceId);
      assert(result === 0, `invalid instruction at PC ${-result - 1}`);
    });
  }

  // ── Yield/resume: single frame ──
  iTest("yield single frame", () => {
    const output = [];
    // Temporarily capture display output
    const origDisplay = ECE.io.display_string;
    const origNumber = ECE.io.display_number;
    // We can't easily redirect — use eval-string and check yield cont
    const evalStr = w.env_lookup(envH, ECE.internSym("eval-string"));
    const src = '(begin (define (test-yield-1) (display "A") (yield) (display "B")) (test-yield-1))';
    w.call_ece_proc(evalStr, w.h_cons(ECE.makeString(src), w.h_nil()));

    // Check yield continuation exists (type 7 = raw continuation with unified call/cc)
    const contH = w.get_yield_cont();
    const contType = w.dbg_type(contH);
    assert(contType === 6 || contType === 7, `expected compiled-proc (6) or continuation (7), got type ${contType}`);

    // Resume
    w.clear_yield_cont();
    if (contType === 7)
      w.call_continuation(contH, w.h_void());
    else
      w.call_ece_proc(contH, w.h_cons(w.h_void(), w.h_nil()));
  });

  // ── Yield/resume: multi-frame ──
  iTest("yield multi-frame (3 cycles)", () => {
    const evalStr = w.env_lookup(envH, ECE.internSym("eval-string"));
    const src = '(begin (define *yc* 0) (define (test-yield-loop) (set! *yc* (+ *yc* 1)) (yield) (test-yield-loop)) (test-yield-loop))';
    w.call_ece_proc(evalStr, w.h_cons(ECE.makeString(src), w.h_nil()));

    for (let frame = 0; frame < 3; frame++) {
      const contH = w.get_yield_cont();
      const contType = w.dbg_type(contH);
      assert(contType === 6 || contType === 7, `frame ${frame}: expected compiled-proc (6) or continuation (7), got type ${contType}`);
      w.clear_yield_cont();
      if (contType === 7)
        w.call_continuation(contH, w.h_void());
      else
        w.call_ece_proc(contH, w.h_cons(w.h_void(), w.h_nil()));
    }

    // Verify counter advanced
    const ycH = w.env_lookup(envH, ECE.internSym("*yc*"));
    const ycVal = w.h_fixnum_val(ycH);
    assert(ycVal === 4, `expected *yc* = 4, got ${ycVal}`);
  });

  // ── Handle stability: reset_handles keeps handles bounded ──
  iTest("handle table stable over 100 yield cycles", () => {
    const evalStr = w.env_lookup(envH, ECE.internSym("eval-string"));
    const src = '(begin (define *hc* 0) (define (test-handle-loop) (set! *hc* (+ *hc* 1)) (yield) (test-handle-loop)) (test-handle-loop))';
    w.call_ece_proc(evalStr, w.h_cons(ECE.makeString(src), w.h_nil()));

    for (let frame = 0; frame < 100; frame++) {
      w.reset_handles();  // simulate what sandbox animationLoop does
      ECE._symCache = {};
      const contH = w.get_yield_cont();
      const contType = w.dbg_type(contH);
      w.clear_yield_cont();
      if (contType === 7)
        w.call_continuation(contH, w.h_void());
      else
        w.call_ece_proc(contH, w.h_cons(w.h_void(), w.h_nil()));
    }

    // Verify counter advanced and we didn't crash
    const hcH = w.env_lookup(envH, ECE.internSym("*hc*"));
    const hcVal = w.h_fixnum_val(hcH);
    assert(hcVal === 101, `expected *hc* = 101, got ${hcVal}`);
  });

  // ── runtime_error import fires with clear message ──
  iTest("runtime_error produces readable exception", () => {
    const sym = ECE.internSym("my-test-var");
    try {
      w.test_runtime_error(sym);
      assert(false, "should have thrown");
    } catch (e) {
      assert(e.message === "Unbound variable: my-test-var",
        `expected 'Unbound variable: my-test-var', got '${e.message}'`);
    }
  });

  // ── Symbol table growth works beyond initial capacity ──
  iTest("symbol intern survives past initial capacity", () => {
    // Intern a large batch of unique symbols — should not crash
    for (let i = 0; i < 1000; i++) {
      ECE.internSym(`stress-test-sym-${i}`);
    }
    // Verify one of them round-trips
    const h = ECE.internSym("stress-test-sym-500");
    const id = w.sym_id(h);
    assert(id > 0, `expected positive sym_id, got ${id}`);
    // Intern the same one again — should get same ID
    const h2 = ECE.internSym("stress-test-sym-500");
    const id2 = w.sym_id(h2);
    assert(id === id2, `expected same id ${id}, got ${id2}`);
  });

  // ── Unbound variable: host-level spot check on the sentinel path.
  // $lookup-variable-value returns an $error-sentinel on miss; the guard/
  // catchable-error scenarios are covered in tests/ece/common/test-error-messages.scm
  // which run inside the ECE test harness.
  iTest("unbound variable: direct lookup returns error sentinel", () => {
    const h = ECE.internSym("definitely-not-bound-zzz");
    const r = w.test_lookup_returns_sentinel(h);
    assert(r === 1, `expected sentinel (1), got ${r}`);
  });
  iTest("unbound variable: bound lookup returns value", () => {
    const h = ECE.internSym("car");
    const r = w.test_lookup_returns_sentinel(h);
    assert(r === 0, `expected value (0), got ${r}`);
  });

  // Serialization round-trip tests are in tests/ece/test-serialization.scm
  // (run as part of the ECE test suite, not as JS integration tests)

  return { passed: iPassed, failed: iFailed };
}

// ── Main test runner ──

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
      trace_pc() {},
      runtime_error(len) {
        const mem = new Uint16Array(ECE.wasm.memory.buffer, 0, len);
        throw new Error(String.fromCharCode(...mem));
      },
      trace_save_restore() {}
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

  // Boot from bootstrap bundle (skip syntax-rules and browser-lib for tests —
  // loading them exposes a continuation/guard interaction that causes the test
  // runner's for-each to re-enter via a stale continuation).
  ECE.globalEnvHandle = envH;
  const bundlePath = path.join(bootstrapDir, "bootstrap.ecec");
  const bundleText = fs.readFileSync(bundlePath, "utf-8").trimEnd();
  console.log("Loading bootstrap bundle...");
  const needed = bundleText.length * 2;
  if (needed > w.memory.buffer.byteLength) {
    w.memory.grow(Math.ceil((needed - w.memory.buffer.byteLength) / 65536));
  }
  const mem = new Uint16Array(w.memory.buffer);
  for (let i = 0; i < bundleText.length; i++) mem[i] = bundleText.charCodeAt(i);
  // Load first 6 sections: boot-env, prelude, compiler, reader, assembler, compilation-unit
  let spaceId = w.load_ecec(0, bundleText.length);
  w.run(spaceId, 0, envH);
  for (let s = 1; s < 6 && w.ecec_has_more(); s++) {
    spaceId = w.load_ecec_continue();
    w.run(spaceId, 0, envH);
  }
  console.log("Bootstrap loaded.");

  // Mark handles after bootstrap so reset_handles() preserves bootstrap state
  w.mark_handles();

  // ── Run integration tests ──
  const intResults = runIntegrationTests(w, envH, output);

  // ── Load and run ECE test suite ──
  if (!fs.existsSync(testFile)) {
    console.error("Test file not found:", testFile);
    process.exit(1);
  }

  const testText = fs.readFileSync(testFile, "utf-8");
  ECE.globalEnvHandle = envH;

  const t0 = Date.now();
  let eceCrash = null;
  try {
    ECE.loadEcecBundleText(testText);
  } catch (e) {
    eceCrash = e.message;
  }
  const elapsed = Date.now() - t0;

  // Print FAIL/ERROR lines from ECE output
  const text = output.join("");
  const lines = text.split("\n");
  for (const line of lines) {
    if (line.includes("FAIL") || line.includes("ERROR:") || line.startsWith("Running")) {
      console.log(line);
    }
  }

  if (eceCrash) {
    console.log(`  CRASH: ${eceCrash}`);
  }

  // Read pass/fail counters directly from the ECE environment.
  // These are accurate even after a crash — they reflect all tests
  // that completed before the crash point.
  let passed = 0, failed = 0;
  try {
    const passH = w.env_lookup(envH, ECE.internSym("*test-passes*"));
    const failH = w.env_lookup(envH, ECE.internSym("*test-failures*"));
    passed = w.h_fixnum_val(passH);
    failed = w.h_fixnum_val(failH);
  } catch (e) {
    // Counters not available — leave at 0
  }

  // Combined results
  const totalPassed = passed + intResults.passed;
  const totalFailed = failed + intResults.failed;

  console.log(`\nWASM tests: ${totalPassed} passed, ${totalFailed} failed (${elapsed}ms)`);
  if (intResults.passed > 0) {
    console.log(`  (${passed} ECE + ${intResults.passed} integration)`);
  }

  if (totalFailed > 0 || eceCrash || passed === 0) {
    process.exit(1);
  }
}

run().catch(e => {
  console.error("WASM test runner error:", e.message);
  process.exit(1);
});
