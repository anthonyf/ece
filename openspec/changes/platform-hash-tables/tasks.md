## 1. Primitive Registration

- [x] 1.1 Assign core primitive IDs 141-149 in `primitives.def`
- [x] 1.2 Add `%make-hash-table` to CL package exports (others already exported)

## 2. CL Host Implementation

- [x] 2.1 Implement CL primitives for platform hash tables
- [x] 2.2 Register in `*wrapper-primitives*`, remove HAMT-specific code
- [x] 2.3 CL tests: 498 passed, 0 failed

## 3. WASM Host Implementation

- [x] 3.1 Wire new core primitive IDs 141-149 in `runtime.wat`
- [x] 3.2 Add `$hash-remove-impl`, `$hash-values-impl` in `runtime.wat`
- [x] 3.3 hash-table? type predicate via ref.test in `runtime.wat`
- [x] 3.4 Register primitives 141-149 in `glue.js` `buildGlobalEnv`

## 4. Prelude Changes

- [x] 4.1 Remove HAMT implementation from `prelude.scm` (~400 lines removed)
- [x] 4.2 Replace `hash-table` constructor with `%make-hash-table` + `hash-set!` loop
- [x] 4.3 Replace `hash-set` (functional) with copy-and-mutate
- [x] 4.4 All HAMT helpers removed (popcount, hash-*, hamt-*)
- [x] 4.5 hash-table stays as ECE function (not macro)

## 5. HAMT Library

- [ ] 5.1 Create `lib/hamt.scm` — move HAMT code from prelude (deferred to separate PR)
- [ ] 5.2 Namespace HAMT functions (deferred)
- [ ] 5.3 Create `tests/ece/test-hamt.scm` (deferred)

## 6. Bootstrap Rebuild

- [x] 6.1 Bootstrap rebuilt (double pass for clean .ecec)
- [x] 6.2 Bootstrap .ececb files regenerated

## 7. Validation

- [x] 7.1 CL tests: rove 1/1 pass, ECE self-hosted 496/0 pass
- [x] 7.2 WASM tests: 326 passed, 3 failed (up from 306/23 — hash tables and records now work!)
- [x] 7.3 WASM tests: record tests pass (define-record uses platform hash tables)
- [x] 7.4 WASM tests: 20 of 23 failures fixed. 3 remain: string->number float, hash-ref default, make-parameter converter
- [ ] 7.5 HAMT library tests pass on CL host (deferred — lib/hamt.scm not yet created)
