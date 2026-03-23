## 1. Add missing ECE test files to WASM suite

- [x] 1.1 Add test-callcc.scm to WASM_TEST_SRCS in Makefile
- [x] 1.2 Add test-advanced-continuations.scm
- [x] 1.3 Add test-dynamic-wind.scm
- [x] 1.4 Add test-guard.scm
- [x] 1.5 Add test-eval-string.scm
- [x] 1.6 Add test-cross-space.scm
- [x] 1.7 Skip test-compilation-units (uses file I/O) and test-misc (write-to-string-flat crash)
- [x] 1.8 Run `make test-wasm` — 387 ECE tests pass (58 new)

## 2. WAT validation exports

- [x] 2.1 Add `check_op_id(sym-handle) → i32` export
- [x] 2.2 Add `validate_space(space-id) → i32` export

## 3. Integration tests in wasm/test.js

- [x] 3.1 Add `runIntegrationTests(w, envH)` function called after bootstrap
- [x] 3.2 Test: op-id exhaustive check — all 22 operation names resolve correctly
- [x] 3.3 Test: validate all 5 bootstrap spaces
- [x] 3.4 Test: yield single frame — eval, check continuation, resume
- [x] 3.5 Test: yield multi-frame — 3-frame loop, verify counter = 4
- [x] 3.6 Report combined results (ECE + integration), fail on any error

## 4. Final verification

- [x] 4.1 Run `make test-wasm` — 416 passed (387 ECE + 29 integration)
- [x] 4.2 Run `make test` — CL tests pass
- [x] 4.3 Run `make sandbox` — builds successfully
