#!/usr/bin/env node
// ECE WASM Test Runner
// Loads the WASM runtime, boots bootstrap, runs compiled tests, reports results.
// Usage: node wasm/test.js [path-to-test.ecec]

const ECE = require("./glue.js");
const fs = require("fs");
const path = require("path");
const os = require("os");
const childProcess = require("child_process");

const testFile = process.argv[2] || path.join(__dirname, "..", "wasm-tests.ecec");
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
        h_cons: w.h_cons,
        h_symbol_1: w.h_symbol_1,
        h_lookup: w.h_lookup,
        h_primitive_p: w.h_primitive_p,
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
    assert(watText.includes('h_lookup'), "generated WAT must look up + through the VM");
    assert(watText.includes('h_apply_primitive'), "generated WAT must apply through the VM");

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
    loader: { fetch_ececb() { return null; } },
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

  // Boot from the bootstrap archive bundle (one or more ecec-archive sexps
  // concatenated — one per compiled source file). loadArchiveBundle loads
  // and runs each archive's init code-object in sequence.
  ECE.globalEnvHandle = envH;
  const bundlePath = path.join(bootstrapDir, "bootstrap.ecec");
  const bundleText = fs.readFileSync(bundlePath, "utf-8").trimEnd();
  console.log("Loading bootstrap bundle...");
  ECE.loadArchiveBundle(bundleText);
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
