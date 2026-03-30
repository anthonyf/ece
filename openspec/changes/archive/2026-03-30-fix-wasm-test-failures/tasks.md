## 1. Fix $fold-sub first-operand type check

- [x] 1.1 Add fixnum check for first arg in `$fold-sub` — set `$all-int` to 0 if first arg is not a fixnum

## 2. Fix $wrap-f64 trunc trap

- [x] 2.1 Guard `i32.trunc_f64_s` in `$wrap-f64` with f64 range check before truncating

## 3. Build and test

- [x] 3.1 Build WASM (`make wasm`) — no compile errors
- [x] 3.2 Run `make test` — CL tests still pass (exit 0)
- [x] 3.3 Run `make test-wasm` — round tests fixed, wrap-f64 trap fixed. Remaining failures are separate pre-existing issues (assert-error/try-eval on WASM, illegal cast crash).

## 4. Enable strict CI

- [ ] 4.1 Remove `continue-on-error: true` — DEFERRED: other pre-existing WASM issues remain (assert-error tests, illegal cast crash)
