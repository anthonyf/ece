#!/usr/bin/env node
// ECE WASM Test Runner
// Loads the WASM runtime, boots bootstrap, runs compiled tests, reports results.
// Usage: node wasm/test.js [path-to-test.ecec] [path-to-binary-fixture.ecec]

const ECE = require("./glue.js");
const fs = require("fs");
const path = require("path");
const os = require("os");
const childProcess = require("child_process");

const testFile = process.argv[2] || path.join(__dirname, "..", "wasm-tests.ecec");
const binaryTestFile = process.argv[3] || null;
const bootstrapDir = path.join(__dirname, "..", "bootstrap");
const wasmFile = path.join(__dirname, "runtime.wasm");

// ── Integration tests (JS↔WASM boundary) ──

function runIntegrationTests(w, envH) {
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

  function eceEval(src) {
    const evalStr = w.env_lookup(envH, ECE.internSym("eval-string-last"));
    return w.call_ece_proc(evalStr, w.h_cons(ECE.makeString(src), w.h_nil()));
  }

  function nativeResult(mode, pc, val, regs) {
    const vec = w.h_vector(8);
    w.h_vector_set(vec, 0, w.h_fixnum(mode));
    w.h_vector_set(vec, 1, w.h_fixnum(pc));
    w.h_vector_set(vec, 2, val);
    w.h_vector_set(vec, 3, regs.env);
    w.h_vector_set(vec, 4, regs.proc);
    w.h_vector_set(vec, 5, regs.argl);
    w.h_vector_set(vec, 6, regs.cont);
    w.h_vector_set(vec, 7, regs.stack);
    return vec;
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

  // ── Yield/resume: single frame ──
  iTest("yield single frame", () => {
    // Execute via eval-string and verify yield/resume through the captured continuation.
    const evalStr = w.env_lookup(envH, ECE.internSym("eval-string"));
    const src = '(begin (define (test-yield-1) (display "A") (yield) (display "B")) (test-yield-1))';
    w.call_ece_proc(evalStr, w.h_cons(ECE.makeString(src), w.h_nil()));

    // Check yield continuation exists (type 7 = raw continuation with unified call/cc)
    const contH = w.get_yield_cont();
    const contType = w.dbg_type(contH);
    assert(contType === 6 || contType === 7, `expected compiled-proc (6) or continuation (7), got type ${contType}`);

    // Resume — runs to completion (no further yield inside test-yield-1).
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

    // The test-yield-loop always yields again after incrementing; the final
    // iteration leaves a yield continuation set. Clear it so later tests in
    // this suite don't inherit stale yield state.
    w.clear_yield_cont();
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
      assert(contType === 6 || contType === 7, `frame ${frame}: expected compiled-proc (6) or continuation (7), got type ${contType}`);
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

    // test-handle-loop always yields again after incrementing; clear the
    // trailing yield state so later tests don't inherit it.
    w.clear_yield_cont();
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
  iTest("compiled entry helper rejects non-compiled procedures with sentinel", () => {
    const r = w.h_compiled_entry(w.h_fixnum(41));
    assert(w.h_error_sentinel_p(r) === 1, "expected compiled entry type error sentinel");
  });

  if (binaryTestFile) {
    iTest("multi-section binary archive bundle loads from bytes", () => {
      const bytes = fs.readFileSync(binaryTestFile);
      ECE.loadArchiveBundleBytes(bytes);
      const result = eceEval("wasm-binary-loader-answer");
      assert(w.h_fixnum_val(result) === 42,
        `expected binary-loaded value 42, got ${w.h_fixnum_val(result)}`);
      const order = ECE._eceListToJsArray(eceEval("wasm-binary-loader-order"));
      assert(JSON.stringify(order) === JSON.stringify([1, 2]),
        `expected multi-section order [1,2], got ${JSON.stringify(order)}`);
    });
  }

  // ── Native-zone entry dispatch smoke ──
  iTest("native zone dispatch returns value", () => {
    globalThis.__eceNativeReturn99 = (regs) =>
      nativeResult(0, 0, regs.wasm.h_fixnum(99), regs);

    const result = eceEval(`
      (begin
        (define native-smoke-co (mc-compile-to-code-object 42))
        (%code-object-set-archive-key! native-smoke-co (cons 'native-smoke 0))
        (register-native-zone! 'native-smoke 0
          (%js-eval "globalThis.__eceNativeReturn99"))
        (execute-code-object native-smoke-co))`);

    assert(w.h_fixnum_val(result) === 99,
      `expected native return 99, got ${w.h_fixnum_val(result)}`);
  });

  iTest("native zone bail falls back to interpreter", () => {
    let calls = 0;
    globalThis.__eceNativeInterpret = (regs) => {
      calls++;
      return nativeResult(2, regs.pc, regs.val, regs);
    };

    const result = eceEval(`
      (begin
        (define native-bail-co (mc-compile-to-code-object 42))
        (%code-object-set-archive-key! native-bail-co (cons 'native-bail 0))
        (register-native-zone! 'native-bail 0
          (%js-eval "globalThis.__eceNativeInterpret"))
        (execute-code-object native-bail-co))`);

    assert(calls === 1, `expected native zone to be called once, got ${calls}`);
    assert(w.h_fixnum_val(result) === 42,
      `expected interpreted fallback 42, got ${w.h_fixnum_val(result)}`);
  });

  iTest("native zone replacement affects future dispatch", () => {
    globalThis.__eceNativeReturn100 = (regs) =>
      nativeResult(0, 0, regs.wasm.h_fixnum(100), regs);

    const first = eceEval(`
      (begin
        (define native-replace-co (mc-compile-to-code-object 41))
        (%code-object-set-archive-key! native-replace-co (cons 'native-replace 0))
        (register-native-zone! 'native-replace 0
          (%js-eval "globalThis.__eceNativeReturn99"))
        (execute-code-object native-replace-co))`);
    const second = eceEval(`
      (begin
        (register-native-zone! 'native-replace 0
          (%js-eval "globalThis.__eceNativeReturn100"))
        (execute-code-object native-replace-co))`);

    assert(w.h_fixnum_val(first) === 99,
      `expected first native return 99, got ${w.h_fixnum_val(first)}`);
    assert(w.h_fixnum_val(second) === 100,
      `expected replacement native return 100, got ${w.h_fixnum_val(second)}`);
  });

  iTest("native zone malformed result reports protocol error", () => {
    globalThis.__eceNativeMalformed = (regs) => regs.val;
    try {
      eceEval(`
        (begin
          (define native-bad-co (mc-compile-to-code-object 7))
          (%code-object-set-archive-key! native-bad-co (cons 'native-bad 0))
          (register-native-zone! 'native-bad 0
            (%js-eval "globalThis.__eceNativeMalformed"))
          (execute-code-object native-bad-co))`);
      assert(false, "expected malformed native result to throw");
    } catch (e) {
      assert(e.message === "native-zone result must be a vector",
        `expected native-zone protocol error, got '${e.message}'`);
    }
  });

  // Serialization round-trip tests are in tests/ece/test-serialization.scm
  // (run as part of the ECE test suite, not as JS integration tests)

  return { passed: iPassed, failed: iFailed };
}

async function runGeneratedZoneIntegrationTests(w, envH) {
  let iPassed = 0, iFailed = 0;

  async function iTest(name, fn) {
    try {
      await fn();
      iPassed++;
    } catch (e) {
      console.log(`  FAIL: ${name}: ${e.message}`);
      iFailed++;
    }
  }

  function assert(cond, msg) {
    if (!cond) throw new Error(msg || "assertion failed");
  }

  function eceEval(src) {
    const evalStr = w.env_lookup(envH, ECE.internSym("eval-string-last"));
    return w.call_ece_proc(evalStr, w.h_cons(ECE.makeString(src), w.h_nil()));
  }

  function compileWat(watText, basename) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ece-zone-"));
    const watPath = path.join(dir, `${basename}.wat`);
    const wasmPath = path.join(dir, `${basename}.wasm`);
    const args = ["--enable-gc", "--enable-reference-types", watPath, "-o", wasmPath];
    try {
      fs.writeFileSync(watPath, watText);
      try {
        childProcess.execFileSync("wasm-as", args, { stdio: "pipe" });
      } catch (e) {
        const stderr = e.stderr ? String(e.stderr).trim() : "";
        const stdout = e.stdout ? String(e.stdout).trim() : "";
        const details = [
          `wasm-as failed: wasm-as ${args.join(" ")}`,
          e.message,
          stderr && `stderr:\n${stderr}`,
          stdout && `stdout:\n${stdout}`
        ].filter(Boolean).join("\n");
        throw new Error(details);
      }
      return fs.readFileSync(wasmPath);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }

  function generatedZoneImports() {
    return {
      ece: {
        h_fixnum: w.h_fixnum,
        h_nil: w.h_nil,
        h_true: w.h_true,
        h_false: w.h_false,
        h_false_p: w.h_false_p,
        h_char: w.h_char,
        h_cons: w.h_cons,
        h_symbol_1: w.h_symbol_1,
        h_symbol_from_chars: w.h_symbol_from_chars,
        h_lookup: w.h_lookup,
        h_primitive_p: w.h_primitive_p,
        h_continuation_p: w.h_continuation_p,
        h_parameter_p: w.h_parameter_p,
        h_compiled_entry: w.h_compiled_entry,
        h_compiled_env: w.h_compiled_env,
        h_make_compiled_proc: w.h_make_compiled_proc,
        h_extend_env: w.h_extend_env,
        h_lexical_ref: w.h_lexical_ref,
        h_lexical_set: w.h_lexical_set,
        h_apply_primitive: w.h_apply_primitive,
        h_error_sentinel_p: w.h_error_sentinel_p,
        pair_car: w.pair_car,
        pair_cdr: w.pair_cdr,
        h_vector: w.h_vector,
        h_vector_set: w.h_vector_set
      }
    };
  }

  await iTest("generated register-machine WASM zone dispatches", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-zone-co (mc-compile-to-code-object 77))
        (%code-object-set-archive-key! generated-zone-co (cons 'generated-zone 0))
        (generate-register-machine-wasm-zone generated-zone-co "zone_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated WAT string");
    assert(watText.includes('(export "zone_0")'), "generated WAT missing export");

    const zoneBytes = compileWat(watText, "generated-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedZone0 = instance.exports.zone_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-zone 0
          (%js-eval "globalThis.__eceGeneratedZone0"))
        (execute-code-object generated-zone-co))`);

    assert(w.h_fixnum_val(result) === 77,
      `expected generated native return 77, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone applies primitive through VM", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-plus-co (mc-compile-to-code-object '(+ 1 2)))
        (%code-object-set-archive-key! generated-plus-co (cons 'generated-plus 0))
        (generate-register-machine-wasm-zone generated-plus-co "zone_plus_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated plus WAT string");
    assert(watText.includes('(export "zone_plus_0")'), "generated WAT missing plus export");
    assert((watText.match(/h_lookup/g) || []).length >= 2,
      "generated WAT must look up + through the VM");
    assert((watText.match(/h_apply_primitive/g) || []).length >= 2,
      "generated WAT must apply through the VM");

    const zoneBytes = compileWat(watText, "generated-plus-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedPlusZone0 = instance.exports.zone_plus_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-plus 0
          (%js-eval "globalThis.__eceGeneratedPlusZone0"))
        (execute-code-object generated-plus-co))`);

    assert(w.h_fixnum_val(result) === 3,
      `expected generated primitive result 3, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone applies nested primitives with stack", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-nested-prims-co
          (mc-compile-to-code-object '(+ (* 2 3) 4)))
        (%code-object-set-archive-key! generated-nested-prims-co
          (cons 'generated-nested-prims 0))
        (generate-register-machine-wasm-zone generated-nested-prims-co
          "zone_nested_prims_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated nested primitive WAT string");
    assert((watText.match(/h_apply_primitive/g) || []).length >= 2,
      "generated WAT must apply primitives beyond the import");
    assert((watText.match(/local\.set \$stack/g) || []).length >= 3,
      "generated WAT must push and pop the ECE stack register");
    assert((watText.match(/call \$h_cons/g) || []).length >= 2,
      "generated WAT must push saved registers with h_cons");
    assert((watText.match(/call \$h_car/g) || []).length >= 2 &&
      (watText.match(/call \$h_cdr/g) || []).length >= 2,
      "generated WAT must restore registers with h_car/h_cdr");

    const zoneBytes = compileWat(watText, "generated-nested-prims-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedNestedPrimsZone0 = instance.exports.zone_nested_prims_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-nested-prims 0
          (%js-eval "globalThis.__eceGeneratedNestedPrimsZone0"))
        (execute-code-object generated-nested-prims-co))`);

    assert(w.h_fixnum_val(result) === 10,
      `expected generated nested primitive result 10, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone bails before non-primitive call dispatch", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-nested-rebind-co
          (mc-compile-to-code-object '(+ (* 2 3) 4)))
        (%code-object-set-archive-key! generated-nested-rebind-co
          (cons 'generated-nested-rebind 0))
        (generate-register-machine-wasm-zone generated-nested-rebind-co
          "zone_nested_rebind_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated nested rebind WAT string");

    const zoneBytes = compileWat(watText, "generated-nested-rebind-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedNestedRebindZone0 = instance.exports.zone_nested_rebind_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-nested-rebind 0
          (%js-eval "globalThis.__eceGeneratedNestedRebindZone0"))
        (define generated-nested-plus-original +)
        (dynamic-wind
          (lambda () (set! + (lambda (a b) 44)))
          (lambda () (execute-code-object generated-nested-rebind-co))
          (lambda () (set! + generated-nested-plus-original))))`);

    assert(w.h_fixnum_val(result) === 44,
      `expected rebound nested primitive fallback result 44, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone prepares compiled procedure calls", async () => {
    const watHandle = eceEval(`
      (begin
        (define (generated-call-target x) (+ x 1))
        (define generated-call-co
          (mc-compile-to-code-object '(generated-call-target 41)))
        (%code-object-set-archive-key! generated-call-co
          (cons 'generated-call 0))
        (generate-register-machine-wasm-zone generated-call-co
          "zone_call_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated call WAT string");
    assert(watText.includes('h_continuation_p'),
      "generated WAT must test continuation dispatch");
    assert(watText.includes('h_parameter_p'),
      "generated WAT must test parameter dispatch");
    assert(watText.includes('h_compiled_entry'),
      "generated WAT must prepare compiled-procedure entry");
    assert(watText.includes('(call $h_cons (local.get $co)'),
      "generated WAT must qualify continue labels with the current code object");

    const zoneBytes = compileWat(watText, "generated-call-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedCallZone0 = instance.exports.zone_call_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-call 0
          (%js-eval "globalThis.__eceGeneratedCallZone0"))
        (execute-code-object generated-call-co))`);

    assert(w.h_fixnum_val(result) === 42,
      `expected compiled procedure call result 42, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zones run lexical procedure bodies", async () => {
    const watHandle = eceEval(`
      (begin
        (define (generated-body-target x) (+ x 1))
        (define generated-body-call-co
          (mc-compile-to-code-object '(generated-body-target 41)))
        (define generated-body-co
          (compiled-procedure-entry generated-body-target))
        (%code-object-set-archive-key! generated-body-call-co
          (cons 'generated-body 0))
        (%code-object-set-archive-key! generated-body-co
          (cons 'generated-body 1))
        (define generated-body-bundle
          (generate-register-machine-wasm-zone-bundle
            'generated-body
            (vector generated-body-call-co generated-body-co)
            "generated-body-zones.wasm"))
        (wasm-zone-bundle-wat generated-body-bundle))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated procedure-body WAT string");
    assert(watText.includes('(export "zone_0")'), "generated WAT missing caller zone");
    assert(watText.includes('(export "zone_1")'), "generated WAT missing body zone");
    assert(watText.includes('h_compiled_env'),
      "generated body WAT must fetch compiled-procedure env");
    assert(watText.includes('h_extend_env'),
      "generated body WAT must extend lexical environment");
    assert(watText.includes('h_lexical_ref'),
      "generated body WAT must read lexical bindings");

    const zoneBytes = compileWat(watText, "generated-body-zones");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedBodyZoneHits = 0;
    globalThis.__eceGeneratedBodyCallerZone0 = instance.exports.zone_0;
    globalThis.__eceGeneratedBodyCalleeZone1 = (regs) => {
      globalThis.__eceGeneratedBodyZoneHits += 1;
      return instance.exports.zone_1(
        regs.pc, regs.val, regs.env, regs.proc,
        regs.argl, regs.cont, regs.stack, regs.co);
    };
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-body 0
          (%js-eval "globalThis.__eceGeneratedBodyCallerZone0"))
        (register-native-zone! 'generated-body 1
          (%js-eval "globalThis.__eceGeneratedBodyCalleeZone1"))
        (execute-code-object generated-body-call-co))`);

    assert(w.h_fixnum_val(result) === 42,
      `expected generated lexical body result 42, got ${w.h_fixnum_val(result)}`);
    assert(globalThis.__eceGeneratedBodyZoneHits === 1,
      `expected generated body zone to run once, got ${globalThis.__eceGeneratedBodyZoneHits}`);
  });

  await iTest("generated register-machine WASM zones create captured closures", async () => {
    const watHandle = eceEval(`
      (begin
        (define (generated-first-child-code-object co)
          (let ((instrs (code-object-instructions co))
                (len (code-object-length co))
                (found #f))
            (let loop ((i 0))
              (when (< i len)
                (let ((instr (vector-ref instrs i)))
                  (when (and (pair? instr)
                             (eq? (car instr) 'assign)
                             (pair? (caddr instr))
                             (eq? (car (caddr instr)) 'op)
                             (eq? (cadr (caddr instr)) 'make-compiled-procedure))
                    (let ((operand (cadddr instr)))
                      (when (and (pair? operand)
                                 (eq? (car operand) 'const)
                                 (code-object? (cadr operand))
                                 (not found))
                        (set! found (cadr operand))))))
                (loop (+ i 1))))
            found))
        (define (generated-closure-make-adder x)
          (lambda (y) (+ x y)))
        (define generated-closure-call-co
          (mc-compile-to-code-object '((generated-closure-make-adder 10) 32)))
        (define generated-closure-maker-co
          (compiled-procedure-entry generated-closure-make-adder))
        (define generated-closure-inner-co
          (generated-first-child-code-object generated-closure-maker-co))
        (%code-object-set-archive-key! generated-closure-call-co
          (cons 'generated-closure 0))
        (%code-object-set-archive-key! generated-closure-maker-co
          (cons 'generated-closure 1))
        (%code-object-set-archive-key! generated-closure-inner-co
          (cons 'generated-closure 2))
        (define generated-closure-bundle
          (generate-register-machine-wasm-zone-bundle
            'generated-closure
            (vector generated-closure-call-co
                    generated-closure-maker-co
                    generated-closure-inner-co)
            "generated-closure-zones.wasm"))
        (wasm-zone-bundle-wat generated-closure-bundle))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated closure WAT string");
    assert(watText.includes('h_make_compiled_proc'),
      "generated WAT must create closures through the VM helper");
    assert(watText.includes('h_lexical_ref'),
      "generated WAT must read captured lexical bindings");

    const zoneBytes = compileWat(watText, "generated-closure-zones");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedClosureMakerHits = 0;
    globalThis.__eceGeneratedClosureInnerHits = 0;
    globalThis.__eceGeneratedClosureCallerZone0 = instance.exports.zone_0;
    globalThis.__eceGeneratedClosureMakerZone1 = (regs) => {
      globalThis.__eceGeneratedClosureMakerHits += 1;
      return instance.exports.zone_1(
        regs.pc, regs.val, regs.env, regs.proc,
        regs.argl, regs.cont, regs.stack, regs.co);
    };
    globalThis.__eceGeneratedClosureInnerZone2 = (regs) => {
      globalThis.__eceGeneratedClosureInnerHits += 1;
      return instance.exports.zone_2(
        regs.pc, regs.val, regs.env, regs.proc,
        regs.argl, regs.cont, regs.stack, regs.co);
    };
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-closure 0
          (%js-eval "globalThis.__eceGeneratedClosureCallerZone0"))
        (register-native-zone! 'generated-closure 1
          (%js-eval "globalThis.__eceGeneratedClosureMakerZone1"))
        (register-native-zone! 'generated-closure 2
          (%js-eval "globalThis.__eceGeneratedClosureInnerZone2"))
        (execute-code-object generated-closure-call-co))`);

    assert(w.h_fixnum_val(result) === 42,
      `expected generated captured closure result 42, got ${w.h_fixnum_val(result)}`);
    assert(globalThis.__eceGeneratedClosureMakerHits === 1,
      `expected generated closure maker zone to run once, got ${globalThis.__eceGeneratedClosureMakerHits}`);
    assert(globalThis.__eceGeneratedClosureInnerHits === 1,
      `expected generated closure body zone to run once, got ${globalThis.__eceGeneratedClosureInnerHits}`);
  });

  await iTest("generated register-machine WASM zones run lexical mutation", async () => {
    const watHandle = eceEval(`
      (begin
        (define (generated-set-target x) (set! x (+ x 1)) x)
        (define generated-set-call-co
          (mc-compile-to-code-object '(generated-set-target 41)))
        (define generated-set-body-co
          (compiled-procedure-entry generated-set-target))
        (%code-object-set-archive-key! generated-set-call-co
          (cons 'generated-set 0))
        (%code-object-set-archive-key! generated-set-body-co
          (cons 'generated-set 1))
        (define generated-set-bundle
          (generate-register-machine-wasm-zone-bundle
            'generated-set
            (vector generated-set-call-co generated-set-body-co)
            "generated-set-zones.wasm"))
        (wasm-zone-bundle-wat generated-set-bundle))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated lexical-set WAT string");
    assert(watText.includes('h_lexical_set'),
      "generated body WAT must write lexical bindings");

    const zoneBytes = compileWat(watText, "generated-set-zones");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedSetZoneHits = 0;
    globalThis.__eceGeneratedSetCallerZone0 = instance.exports.zone_0;
    globalThis.__eceGeneratedSetCalleeZone1 = (regs) => {
      globalThis.__eceGeneratedSetZoneHits += 1;
      return instance.exports.zone_1(
        regs.pc, regs.val, regs.env, regs.proc,
        regs.argl, regs.cont, regs.stack, regs.co);
    };
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-set 0
          (%js-eval "globalThis.__eceGeneratedSetCallerZone0"))
        (register-native-zone! 'generated-set 1
          (%js-eval "globalThis.__eceGeneratedSetCalleeZone1"))
        (execute-code-object generated-set-call-co))`);

    assert(w.h_fixnum_val(result) === 42,
      `expected generated lexical mutation result 42, got ${w.h_fixnum_val(result)}`);
    assert(globalThis.__eceGeneratedSetZoneHits === 1,
      `expected generated set body zone to run once, got ${globalThis.__eceGeneratedSetZoneHits}`);
  });

  await iTest("generated register-machine WASM zones run dotted parameters", async () => {
    const watHandle = eceEval(`
      (begin
        (define (generated-rest-target x . rest) rest)
        (define generated-rest-call-co
          (mc-compile-to-code-object '(generated-rest-target 1 2 3)))
        (define generated-rest-body-co
          (compiled-procedure-entry generated-rest-target))
        (%code-object-set-archive-key! generated-rest-call-co
          (cons 'generated-rest 0))
        (%code-object-set-archive-key! generated-rest-body-co
          (cons 'generated-rest 1))
        (define generated-rest-bundle
          (generate-register-machine-wasm-zone-bundle
            'generated-rest
            (vector generated-rest-call-co generated-rest-body-co)
            "generated-rest-zones.wasm"))
        (wasm-zone-bundle-wat generated-rest-bundle))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated rest-parameter WAT string");
    assert(watText.includes('h_symbol_from_chars'),
      "generated WAT must lower multi-character rest parameter symbols");
    assert(watText.includes('h_extend_env'),
      "generated WAT must extend lexical environment for rest parameters");

    const zoneBytes = compileWat(watText, "generated-rest-zones");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedRestZoneHits = 0;
    globalThis.__eceGeneratedRestCallerZone0 = instance.exports.zone_0;
    globalThis.__eceGeneratedRestCalleeZone1 = (regs) => {
      globalThis.__eceGeneratedRestZoneHits += 1;
      return instance.exports.zone_1(
        regs.pc, regs.val, regs.env, regs.proc,
        regs.argl, regs.cont, regs.stack, regs.co);
    };
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-rest 0
          (%js-eval "globalThis.__eceGeneratedRestCallerZone0"))
        (register-native-zone! 'generated-rest 1
          (%js-eval "globalThis.__eceGeneratedRestCalleeZone1"))
        (execute-code-object generated-rest-call-co))`);

    const values = ECE._eceListToJsArray(result);
    assert(JSON.stringify(values) === JSON.stringify([2, 3]),
      `expected generated rest result (2 3), got ${JSON.stringify(values)}`);
    assert(globalThis.__eceGeneratedRestZoneHits === 1,
      `expected generated rest body zone to run once, got ${globalThis.__eceGeneratedRestZoneHits}`);
  });

  await iTest("generated register-machine WASM zone bails on non-procedure call", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-not-proc 41)
        (define generated-not-proc-co
          (mc-compile-to-code-object '(generated-not-proc)))
        (%code-object-set-archive-key! generated-not-proc-co
          (cons 'generated-not-proc 0))
        (generate-register-machine-wasm-zone generated-not-proc-co
          "zone_not_proc_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated non-procedure WAT string");
    assert(watText.includes('h_compiled_entry'),
      "generated WAT must prepare compiled-procedure entry");
    assert(watText.includes('h_error_sentinel_p'),
      "generated WAT must check compiled-entry type errors");

    const zoneBytes = compileWat(watText, "generated-not-proc-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedNotProcZone0 = instance.exports.zone_not_proc_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-not-proc 0
          (%js-eval "globalThis.__eceGeneratedNotProcZone0"))
        (guard (e ((error-object? e) (error-object-message e)))
          (execute-code-object generated-not-proc-co)))`);

    const message = ECE._eceToJs(result);
    assert(message === "compiled-procedure-entry: not a compiled procedure",
      `expected catchable non-procedure call error, got ${JSON.stringify(message)}`);
  });

  await iTest("generated register-machine WASM zone runs conditional control flow", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-if-false-co (mc-compile-to-code-object '(if #f 1 2)))
        (%code-object-set-archive-key! generated-if-false-co
          (cons 'generated-if-false 0))
        (define generated-if-true-co (mc-compile-to-code-object '(if 7 11 22)))
        (%code-object-set-archive-key! generated-if-true-co
          (cons 'generated-if-true 0))
        (define generated-if-bundle
          (generate-register-machine-wasm-zone-bundle
            'generated-if
            (vector generated-if-false-co generated-if-true-co)
            "generated-if-zones.wasm"))
        (wasm-zone-bundle-wat generated-if-bundle))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated if WAT string");
    assert(watText.includes('h_false_p'), "generated WAT must test false? through handle helper");
    assert(watText.includes('(loop $dispatch'), "generated WAT must keep logical pc dispatch");

    const zoneBytes = compileWat(watText, "generated-if-zones");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedIfFalseZone0 = instance.exports.zone_0;
    globalThis.__eceGeneratedIfTrueZone0 = instance.exports.zone_1;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-if-false 0
          (%js-eval "globalThis.__eceGeneratedIfFalseZone0"))
        (register-native-zone! 'generated-if-true 0
          (%js-eval "globalThis.__eceGeneratedIfTrueZone0"))
        (list
          (execute-code-object generated-if-false-co)
          (execute-code-object generated-if-true-co)))`);

    const values = ECE._eceListToJsArray(result);
    assert(values.length === 2 && values[0] === 2 && values[1] === 11,
      `expected generated if results (2 11), got ${JSON.stringify(values)}`);
  });

  await iTest("generated register-machine WASM zone bails after native branch", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-branch-bail-co (%make-code-object))
        (%code-object-push-instruction! generated-branch-bail-co
          '(assign val (const #f)))
        (%code-object-push-instruction! generated-branch-bail-co
          '(test (op false?) (reg val)))
        (%code-object-push-instruction! generated-branch-bail-co
          '(branch (label branch-bail-target)))
        (%code-object-push-instruction! generated-branch-bail-co
          '(assign val (const 9)))
        (%code-object-push-instruction! generated-branch-bail-co '(halt))
        (%code-object-set-label! generated-branch-bail-co 'branch-bail-target 5)
        (%code-object-push-instruction! generated-branch-bail-co
          '(perform (op define-variable!) (const generated-branch-bail-value)
                    (reg val) (reg env)))
        (%code-object-push-instruction! generated-branch-bail-co '(halt))
        (%code-object-set-archive-key! generated-branch-bail-co
          (cons 'generated-branch-bail 0))
        (generate-register-machine-wasm-zone generated-branch-bail-co
          "zone_branch_bail_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated branch bailout WAT string");
    assert(watText.includes('(br $dispatch)'), "generated WAT must loop after branch");

    const zoneBytes = compileWat(watText, "generated-branch-bail-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedBranchBailZone0 = instance.exports.zone_branch_bail_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-branch-bail 0
          (%js-eval "globalThis.__eceGeneratedBranchBailZone0"))
        (execute-code-object generated-branch-bail-co)
        (if generated-branch-bail-value 1 0))`);

    assert(w.h_fixnum_val(result) === 0,
      `expected branch bailout to preserve #f val, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone applies longer-name primitive", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-string-co (mc-compile-to-code-object '(string-length generated-string-input)))
        (%code-object-set-archive-key! generated-string-co
          (cons 'generated-string 0))
        (generate-register-machine-wasm-zone generated-string-co
          "zone_string_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated string WAT string");
    assert(watText.includes('h_symbol_from_chars'),
      "generated WAT must build longer symbols through character handles");

    const zoneBytes = compileWat(watText, "generated-string-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedStringZone0 = instance.exports.zone_string_0;
    const result = eceEval(`
      (begin
        (define generated-string-input "hello")
        (register-native-zone! 'generated-string 0
          (%js-eval "globalThis.__eceGeneratedStringZone0"))
        (execute-code-object generated-string-co))`);

    assert(w.h_fixnum_val(result) === 5,
      `expected generated string-length result 5, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone bails if longer-name primitive changes", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-string-rebind-co
          (mc-compile-to-code-object '(string-length generated-string-rebind-input)))
        (%code-object-set-archive-key! generated-string-rebind-co
          (cons 'generated-string-rebind 0))
        (generate-register-machine-wasm-zone generated-string-rebind-co
          "zone_string_rebind_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated string rebind WAT string");

    const zoneBytes = compileWat(watText, "generated-string-rebind-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedStringRebindZone0 = instance.exports.zone_string_rebind_0;
    const result = eceEval(`
      (begin
        (define generated-string-rebind-input "hello")
        (register-native-zone! 'generated-string-rebind 0
          (%js-eval "globalThis.__eceGeneratedStringRebindZone0"))
        (define generated-string-length-original string-length)
        (dynamic-wind
          (lambda () (set! string-length (lambda (s) 44)))
          (lambda () (execute-code-object generated-string-rebind-co))
          (lambda () (set! string-length generated-string-length-original))))`);

    assert(w.h_fixnum_val(result) === 44,
      `expected rebound string-length fallback result 44, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone applies primitive to variable list value", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-car-co (mc-compile-to-code-object '(car generated-car-input)))
        (%code-object-set-archive-key! generated-car-co
          (cons 'generated-car 0))
        (generate-register-machine-wasm-zone generated-car-co
          "zone_car_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated car WAT string");
    assert(watText.includes('h_symbol_from_chars'),
      "generated WAT must build car/generated-car-input symbols");

    const zoneBytes = compileWat(watText, "generated-car-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedCarZone0 = instance.exports.zone_car_0;
    const result = eceEval(`
      (begin
        (define generated-car-input (list 9 8))
        (register-native-zone! 'generated-car 0
          (%js-eval "globalThis.__eceGeneratedCarZone0"))
        (execute-code-object generated-car-co))`);

    assert(w.h_fixnum_val(result) === 9,
      `expected generated car result 9, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone bails on lookup error sentinel", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-plus-unbound-co (mc-compile-to-code-object '(+ x 2)))
        (%code-object-set-archive-key! generated-plus-unbound-co
          (cons 'generated-plus-unbound 0))
        (generate-register-machine-wasm-zone generated-plus-unbound-co
          "zone_plus_unbound_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated plus unbound WAT string");
    assert(watText.includes('h_error_sentinel_p'), "generated WAT must check lookup errors");

    const zoneBytes = compileWat(watText, "generated-plus-unbound-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedPlusUnboundZone0 = instance.exports.zone_plus_unbound_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-plus-unbound 0
          (%js-eval "globalThis.__eceGeneratedPlusUnboundZone0"))
        (guard (e ((error-object? e) (error-object-message e)))
          (execute-code-object generated-plus-unbound-co)))`);

    const message = ECE._eceToJs(result);
    assert(message === "Unbound variable: x",
      `expected catchable unbound x error, got ${JSON.stringify(message)}`);
  });

  await iTest("generated register-machine WASM zone bails if primitive binding changes", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-plus-rebind-co (mc-compile-to-code-object '(+ 1 2)))
        (%code-object-set-archive-key! generated-plus-rebind-co
          (cons 'generated-plus-rebind 0))
        (generate-register-machine-wasm-zone generated-plus-rebind-co
          "zone_plus_rebind_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated plus rebind WAT string");

    const zoneBytes = compileWat(watText, "generated-plus-rebind-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedPlusRebindZone0 = instance.exports.zone_plus_rebind_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-plus-rebind 0
          (%js-eval "globalThis.__eceGeneratedPlusRebindZone0"))
        (define generated-plus-original +)
        (set! + (lambda (a b) 44))
        (define generated-plus-rebound-result
          (execute-code-object generated-plus-rebind-co))
        (set! + generated-plus-original)
        generated-plus-rebound-result)`);

    assert(w.h_fixnum_val(result) === 44,
      `expected rebound + fallback result 44, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone returns direct nil constant", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-nil-co (%make-code-object))
        (%code-object-push-instruction! generated-nil-co
          '(assign val (const ())))
        (%code-object-push-instruction! generated-nil-co '(halt))
        (%code-object-set-archive-key! generated-nil-co (cons 'generated-nil 0))
        (generate-register-machine-wasm-zone generated-nil-co "zone_nil_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated nil WAT string");
    assert(watText.includes('(export "zone_nil_0")'), "generated WAT missing nil export");
    assert(watText.includes('(call $h_nil)'), "generated WAT missing direct nil call");

    const zoneBytes = compileWat(watText, "generated-nil-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedNilZone0 = instance.exports.zone_nil_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-nil 0
          (%js-eval "globalThis.__eceGeneratedNilZone0"))
        (if (null? (execute-code-object generated-nil-co)) 1 0))`);

    assert(w.h_fixnum_val(result) === 1,
      `expected generated nil return to satisfy null?, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone bails out with updated registers", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-bail-co (%make-code-object))
        (%code-object-push-instruction! generated-bail-co
          '(assign val (const 88)))
        (%code-object-push-instruction! generated-bail-co
          '(perform (op define-variable!) (const generated-bail-value)
                    (reg val) (reg env)))
        (%code-object-push-instruction! generated-bail-co
          '(assign val (const 99)))
        (%code-object-push-instruction! generated-bail-co '(halt))
        (%code-object-set-archive-key! generated-bail-co (cons 'generated-bail 0))
        (generate-register-machine-wasm-zone generated-bail-co "zone_bail_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated bailout WAT string");
    assert(watText.includes('(export "zone_bail_0")'), "generated WAT missing bailout export");
    assert(watText.includes('(i32.const 2)'), "generated WAT missing bailout mode");

    const zoneBytes = compileWat(watText, "generated-bail-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedBailZone0 = instance.exports.zone_bail_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-bail 0
          (%js-eval "globalThis.__eceGeneratedBailZone0"))
        (execute-code-object generated-bail-co)
        generated-bail-value)`);

    assert(w.h_fixnum_val(result) === 88,
      `expected bailout to preserve generated val 88, got ${w.h_fixnum_val(result)}`);
  });

  await iTest("generated register-machine WASM zone builds list prefix before bailout", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-list-co (%make-code-object))
        (%code-object-push-instruction! generated-list-co
          '(assign val (const 5)))
        (%code-object-push-instruction! generated-list-co
          '(assign argl (op list) (reg val)))
        (%code-object-push-instruction! generated-list-co
          '(assign val (const 3)))
        (%code-object-push-instruction! generated-list-co
          '(assign argl (op cons) (reg val) (reg argl)))
        (%code-object-push-instruction! generated-list-co
          '(perform (op define-variable!) (const generated-list-value)
                    (reg argl) (reg env)))
        (%code-object-push-instruction! generated-list-co '(halt))
        (%code-object-set-archive-key! generated-list-co (cons 'generated-list 0))
        (generate-register-machine-wasm-zone generated-list-co "zone_list_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated list WAT string");
    assert(watText.includes('(export "zone_list_0")'), "generated WAT missing list export");
    assert(watText.includes('h_cons'), "generated WAT missing cons import/call");

    const zoneBytes = compileWat(watText, "generated-list-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedListZone0 = instance.exports.zone_list_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-list 0
          (%js-eval "globalThis.__eceGeneratedListZone0"))
        (execute-code-object generated-list-co)
        generated-list-value)`);

    const values = ECE._eceListToJsArray(result);
    assert(values.length === 2 && values[0] === 3 && values[1] === 5,
      `expected generated list (3 5), got ${JSON.stringify(values)}`);
  });

  await iTest("generated register-machine WASM zone reads pair car and cdr", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-pair-co (%make-code-object))
        (%code-object-push-instruction! generated-pair-co
          '(assign val (const 9)))
        (%code-object-push-instruction! generated-pair-co
          '(assign argl (op cons) (reg val) (const ())))
        (%code-object-push-instruction! generated-pair-co
          '(assign proc (op car) (reg argl)))
        (%code-object-push-instruction! generated-pair-co
          '(assign argl (op cdr) (reg argl)))
        (%code-object-push-instruction! generated-pair-co
          '(assign val (op list) (reg proc) (reg argl)))
        (%code-object-push-instruction! generated-pair-co '(halt))
        (%code-object-set-archive-key! generated-pair-co (cons 'generated-pair 0))
        (generate-register-machine-wasm-zone generated-pair-co "zone_pair_0"))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated pair WAT string");
    assert(watText.includes('(export "zone_pair_0")'), "generated WAT missing pair export");
    assert(watText.includes('pair_car'), "generated WAT missing pair_car import");
    assert(watText.includes('pair_cdr'), "generated WAT missing pair_cdr import");

    const zoneBytes = compileWat(watText, "generated-pair-zone");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedPairZone0 = instance.exports.zone_pair_0;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-pair 0
          (%js-eval "globalThis.__eceGeneratedPairZone0"))
        (execute-code-object generated-pair-co))`);

    const values = ECE._eceListToJsArray(result);
    assert(values.length === 2 && values[0] === 9 && values[1] === null,
      `expected generated pair access result (9 null), got ${JSON.stringify(values)}`);
  });

  await iTest("generated register-machine WASM zone bundle registers supported entries", async () => {
    const watHandle = eceEval(`
      (begin
        (define generated-bundle-co0 (mc-compile-to-code-object 12))
        (%code-object-set-archive-key! generated-bundle-co0
          (cons 'generated-bundle 0))
        (define generated-bundle-co1 (mc-compile-to-code-object '(+ 1 2)))
        (%code-object-set-archive-key! generated-bundle-co1
          (cons 'generated-bundle 1))
        (define generated-bundle-co2 (%make-code-object))
        (%code-object-push-instruction! generated-bundle-co2
          '(assign val (const ())))
        (%code-object-push-instruction! generated-bundle-co2 '(halt))
        (%code-object-set-archive-key! generated-bundle-co2
          (cons 'generated-bundle 2))
        (define generated-bundle
          (generate-register-machine-wasm-zone-bundle
            'generated-bundle
            (vector generated-bundle-co0
                    generated-bundle-co1
                    generated-bundle-co2)
            "generated-bundle-zones.wasm"))
        (wasm-zone-bundle-wat generated-bundle))`);
    const watText = ECE._eceToJs(watHandle);
    assert(typeof watText === "string", "expected generated bundle WAT string");
    assert(watText.includes('(export "zone_0")'), "bundle WAT missing zone_0");
    assert(watText.includes('(export "zone_1")'), "bundle WAT missing zone_1");
    assert(watText.includes('(export "zone_2")'), "bundle WAT missing zone_2");

    const zoneBytes = compileWat(watText, "generated-bundle-zones");
    const { instance } = await WebAssembly.instantiate(zoneBytes, generatedZoneImports());

    globalThis.__eceGeneratedBundleZone0 = instance.exports.zone_0;
    globalThis.__eceGeneratedBundleZone1 = instance.exports.zone_1;
    globalThis.__eceGeneratedBundleZone2 = instance.exports.zone_2;
    const result = eceEval(`
      (begin
        (register-native-zone! 'generated-bundle 0
          (%js-eval "globalThis.__eceGeneratedBundleZone0"))
        (register-native-zone! 'generated-bundle 1
          (%js-eval "globalThis.__eceGeneratedBundleZone1"))
        (register-native-zone! 'generated-bundle 2
          (%js-eval "globalThis.__eceGeneratedBundleZone2"))
        (list
          (execute-code-object generated-bundle-co0)
          (execute-code-object generated-bundle-co1)
          (if (null? (execute-code-object generated-bundle-co2)) 1 0)))`);

    const values = ECE._eceListToJsArray(result);
    assert(values.length === 3 && values[0] === 12 && values[1] === 3 && values[2] === 1,
      `expected bundle results (12 3 1), got ${JSON.stringify(values)}`);
  });

  await iTest("load-native-zone-module registers generated bundle exports", async () => {
    ECE.wasmHost.clearResources();
    const bundleInfo = eceEval(`
      (begin
        (define host-load-co0 (mc-compile-to-code-object 21))
        (%code-object-set-archive-key! host-load-co0 (cons 'host-load 0))
        (define host-load-co1 (mc-compile-to-code-object '(+ 1 2)))
        (%code-object-set-archive-key! host-load-co1 (cons 'host-load 1))
        (define host-load-bundle
          (generate-register-machine-wasm-zone-bundle
            'host-load
            (vector host-load-co0 host-load-co1)
            "host-load-zones.wasm"))
        (list
          (wasm-zone-bundle-wat host-load-bundle)
          (wasm-zone-bundle-manifest-text host-load-bundle)))`);
    const [watText, manifestText] = ECE._eceListToJsArray(bundleInfo);
    ECE.wasmHost.setBytes("host-load-zones.wasm",
      compileWat(watText, "host-load-zones"));
    ECE.wasmHost.setText("host-load-zones.manifest", manifestText);

    const result = eceEval(`
      (begin
        (load-native-zone-module "host-load-zones.wasm"
                                 "host-load-zones.manifest")
        (list
          (execute-code-object host-load-co0)
          (execute-code-object host-load-co1)))`);

    const values = ECE._eceListToJsArray(result);
    assert(values.length === 2 && values[0] === 21 && values[1] === 3,
      `expected loaded native/interpreted results (21 3), got ${JSON.stringify(values)}`);
  });

  await iTest("load-native-zone-module reload replaces registered export", async () => {
    ECE.wasmHost.clearResources();
    const reloadInfo = eceEval(`
      (begin
        (define host-reload-co (mc-compile-to-code-object 0))
        (%code-object-set-archive-key! host-reload-co (cons 'host-reload 0))
        (define host-reload-co-a (mc-compile-to-code-object 31))
        (define host-reload-co-b (mc-compile-to-code-object 32))
        (define host-reload-bundle-a
          (generate-register-machine-wasm-zone-bundle
            'host-reload
            (vector host-reload-co-a)
            "host-reload-a.wasm"))
        (define host-reload-bundle-b
          (generate-register-machine-wasm-zone-bundle
            'host-reload
            (vector host-reload-co-b)
            "host-reload-b.wasm"))
        (list
          (wasm-zone-bundle-wat host-reload-bundle-a)
          (wasm-zone-bundle-manifest-text host-reload-bundle-a)
          (wasm-zone-bundle-wat host-reload-bundle-b)
          (wasm-zone-bundle-manifest-text host-reload-bundle-b)))`);
    const [watA, manifestA, watB, manifestB] = ECE._eceListToJsArray(reloadInfo);
    ECE.wasmHost.setBytes("host-reload-a.wasm",
      compileWat(watA, "host-reload-a"));
    ECE.wasmHost.setText("host-reload-a.manifest", manifestA);
    ECE.wasmHost.setBytes("host-reload-b.wasm",
      compileWat(watB, "host-reload-b"));
    ECE.wasmHost.setText("host-reload-b.manifest", manifestB);

    const result = eceEval(`
      (begin
        (load-native-zone-module "host-reload-a.wasm"
                                 "host-reload-a.manifest")
        (define host-reload-first (execute-code-object host-reload-co))
        (load-native-zone-module "host-reload-b.wasm"
                                 "host-reload-b.manifest")
        (list host-reload-first (execute-code-object host-reload-co)))`);

    const values = ECE._eceListToJsArray(result);
    assert(values.length === 2 && values[0] === 31 && values[1] === 32,
      `expected reload results (31 32), got ${JSON.stringify(values)}`);
  });

  await iTest("load-native-zone-module reports missing exports", async () => {
    ECE.wasmHost.clearResources();
    const bundleInfo = eceEval(`
      (begin
        (define host-missing-co (mc-compile-to-code-object 44))
        (define host-missing-bundle
          (generate-register-machine-wasm-zone-bundle
            'host-missing
            (vector host-missing-co)
            "host-missing.wasm"))
        (list
          (wasm-zone-bundle-wat host-missing-bundle)
          (wasm-zone-manifest->text
            (generate-register-machine-wasm-zone-manifest
              'host-missing
              0
              "missing_zone"
              "host-missing.wasm"))))`);
    const [missingWat, missingManifest] = ECE._eceListToJsArray(bundleInfo);
    ECE.wasmHost.setBytes("host-missing.wasm",
      compileWat(missingWat, "host-missing"));
    ECE.wasmHost.setText("host-missing.manifest", missingManifest);

    try {
      eceEval(`
        (load-native-zone-module "host-missing.wasm"
                                 "host-missing.manifest")`);
      assert(false, "expected missing export to throw");
    } catch (e) {
      assert(e.message === "wasm-host: missing WASM export: missing_zone",
        `expected missing export error, got '${e.message}'`);
    }
  });

  await iTest("reload-program loads archive and native-zone artifacts", async () => {
    ECE.wasmHost.clearResources();
    const reloadProgramInfo = eceEval(`
      (begin
        (define reload-program-zone-co (mc-compile-to-code-object 91))
        (define reload-program-archive
          (code-object->archive-sexp
            reload-program-zone-co
            "reload-program.scm"
            (list ':unit-id 'reload-program-unit)))
        (define reload-program-archive-text
          (write-to-string-flat reload-program-archive))
        (define reload-program-bundle
          (generate-register-machine-wasm-zone-archive-text
            reload-program-archive-text
            "reload-program-zones.wasm"))
        (list
          reload-program-archive-text
          (wasm-zone-bundle-wat reload-program-bundle)
          (wasm-zone-bundle-manifest-text reload-program-bundle)))`);
    const [archiveText, zoneWat, zoneManifest] = ECE._eceListToJsArray(reloadProgramInfo);
    ECE.wasmHost.setText("reload-program.ecec", archiveText);
    ECE.wasmHost.setBytes("reload-program-zones.wasm",
      compileWat(zoneWat, "reload-program-zones"));
    ECE.wasmHost.setText("reload-program-zones.manifest", zoneManifest);

    const result = eceEval(`
      (begin
        (reload-program "reload-program.ecec"
                        "reload-program-zones.wasm"
                        "reload-program-zones.manifest")
        (let* ((unit (archive/registered-unit 'reload-program-unit))
               (cos (hash-ref unit ':cos #f))
               (co (vector-ref cos 0)))
          (execute-code-object co)))`);

    assert(ECE._eceToJs(result) === 91,
      `expected reload-program native result 91, got ${ECE._eceToJs(result)}`);
  });

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
    storage: ECE.storage,
    canvas: ECE.canvas,
    timing: ECE.timing,
    math: ECE.math,
    ffi: ECE.ffi,
    wasm_host: ECE.wasmHost
  };

  const { instance } = await WebAssembly.instantiate(wasmBytes, imports);
  ECE.wasm = instance.exports;
  const w = ECE.wasm;

  // Build global environment
  const envH = ECE.buildGlobalEnv();

  // Boot from the bootstrap archive bundle. loadArchiveBundleAuto accepts
  // either the binary .ecec bootstrap or the printed compatibility form.
  ECE.globalEnvHandle = envH;
  const bundlePath = path.join(bootstrapDir, "bootstrap.ecec");
  const bundleBytes = fs.readFileSync(bundlePath);
  console.log("Loading bootstrap bundle...");
  ECE.loadArchiveBundleAuto(bundleBytes);
  console.log("Bootstrap loaded.");

  // Mark handles after bootstrap so reset_handles() preserves bootstrap state
  w.mark_handles();

  // ── Run integration tests ──
  const intResults = runIntegrationTests(w, envH);

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
    const testCo = ECE.loadArchiveText(testText);
    ECE.runCodeObject(testCo);
  } catch (e) {
    eceCrash = e.message;
  }
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

  const generatedZoneResults = await runGeneratedZoneIntegrationTests(w, envH);
  const elapsed = Date.now() - t0;

  // Combined results
  const totalPassed = passed + intResults.passed + generatedZoneResults.passed;
  const totalFailed = failed + intResults.failed + generatedZoneResults.failed;

  console.log(`\nWASM tests: ${totalPassed} passed, ${totalFailed} failed (${elapsed}ms)`);
  if (intResults.passed > 0 || generatedZoneResults.passed > 0) {
    console.log(`  (${passed} ECE + ${intResults.passed + generatedZoneResults.passed} integration)`);
  }

  if (totalFailed > 0 || eceCrash || passed === 0) {
    process.exit(1);
  }
}

run().catch(e => {
  console.error("WASM test runner error:", e.message);
  console.error(e.stack);
  process.exit(1);
});
