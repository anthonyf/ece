## 1. Implement %raw-error on WASM

- [x] 1.1 Add primitive 81 dispatch in `$apply-primitive` to call `$signal-error-str` with the string argument

## 2. Add zero checks to ECE prelude

- [x] 2.1 Add zero-divisor check to `quotient` in `prelude.scm` — call `(error "/: division by zero")` if `b` is 0
- [x] 2.2 Add zero-divisor check to `modulo` in `prelude.scm`
- [x] 2.3 Add zero-divisor check to `remainder` in `prelude.scm`

## 3. Clean up WAT division check

- [x] 3.1 Remove the `$fold-div` zero-divisor check from `runtime.wat` (ECE prelude handles it now)
- [x] 3.2 Remove `$err-div-zero` global string constant from `runtime.wat`

## 4. Re-enable guard tests on WASM

- [x] 4.1 Re-add `test-guard.scm` to `WASM_TEST_SRCS` in Makefile
- [x] 4.2 Move division-by-zero guard tests from `test-arithmetic.scm` to `test-guard.scm`
- [x] 4.3 Remove the `platform-has? 'try-eval` guard from division-by-zero tests (now catchable on all platforms)

## 5. Bootstrap and test

- [x] 5.1 Two-pass bootstrap (`make bootstrap` x2 with FASL clear)
- [x] 5.2 Run `make test` — CL tests pass (exit 0)
- [x] 5.3 Run `make test-wasm` — 478 passed (444 ECE + 34 integration), 0 failed (exit 0)
