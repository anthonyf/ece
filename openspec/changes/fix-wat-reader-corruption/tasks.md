## 1. Build comparison tool

- [ ] 1.1 Extract `parseBinary` and `loadParsed` from git history (d316763) into a standalone module
- [ ] 1.2 Extract prelude.ececb from git history for comparison
- [ ] 1.3 Create `wasm/compare-loaders.js`: loads prelude via binary AND WAT, diffs all val fields
- [ ] 1.4 Run comparison, capture full diff output

## 2. Analyze differences

- [x] 2.1 RESULT: Zero differences found — all i32 fields, val types, and val string representations match across all 27,552 instructions
- [x] 2.2 The WAT reader is NOT the problem. The bug is in runtime execution — the same instructions produce different behavior when loaded via WAT reader vs binary loader.
- [ ] 2.3 Investigate: handle table state differences, execution context differences, or V8 optimization differences between the two loading paths

## 3. Runtime execution investigation (revised scope)

- [x] 3.1 Comparison tool confirmed: zero instruction differences between WAT reader and binary loader
- [x] 3.2 Global env frame identity (eq?) works correctly — %global-env-frame returns same identity
- [x] 3.3 Direct call via call_ece_proc crashes at space 13861 (compilation-unit), PC 3626 — executor runs off end of wrong space
- [x] 3.4 Confirmed: serialize-value was NEVER working on WASM (write-to-string-flat was CL-only). After adding it, atoms/pairs/lambdas/vectors work but proper lists crash.
- [x] 3.5 Binary-loaded prelude also crashes with direct call_ece_proc → NOT a WAT reader issue
- [x] 3.6 Through eval-string: atoms work, lists crash. Runtime-compiled identical logic works.
- [x] 3.7 Root cause: prelude-compiled code for nested closures (proper-list? / ser-pair list loop) has a latent issue when loaded from .ecec on WASM. This is NOT a WAT reader corruption — the instructions are identical. It's likely a V8 WasmGC JIT issue with deeply nested closures crossing compile-time vs runtime compilation boundaries.

## 4. Fix prelude serializer

- [x] 4.1 Root cause: 3-arg string-append with recursive named-let call as inline argument in ser-pair's list loop. Complex nested argument evaluation in the compiler output interacts badly with save/restore when loaded from .ecec.
- [x] 4.2 Fix: rewrite list loop to use explicit let bindings before string-append
- [x] 4.3 User code unaffected — pattern only fails in prelude-compiled code, not runtime-compiled
- [x] 4.4 Rebuild bootstrap (make bootstrap x2)

## 5. Verify and test

- [x] 5.1 Run make test-wasm — 424 passed, 0 failed (387 ECE + 37 integration)
- [x] 5.2 Run make test — CL tests pass
- [x] 5.3 Serialization integration tests added: list, pair, lambda, primitive, round-trip, save/load
- [x] 5.4 All serialization tests pass

## 6. Known issue: compiler arg evaluation bug

The underlying issue is NOT the WAT reader — it's a compiler code generation bug with multi-arg function calls where arguments include recursive calls. The compiler's `mc-construct-arglist` evaluates args in reverse order with nested `save/restore`, which interacts badly with the executor when loaded from bootstrap .ecec. User code is unaffected (runtime-compiled). The workaround (explicit let bindings in prelude source) is sufficient for now. A proper compiler fix is a separate change.
