## 1. Implement number->string in ECE

- [x] 1.1 Add `number->string` to `prelude.scm` in the integer arithmetic section (after `modulo`, before derived predicates) — recursive digit extraction via `quotient`/`modulo`/`integer->char`/`string`/`string-append`
- [x] 1.2 Verify ordering: `number->string` after `quotient`/`modulo`, before `gensym`

## 2. Remove from CL host

- [x] 2.1 Remove `ece-number->string` function from `runtime.lisp`
- [x] 2.2 Remove `(number->string . ece-number->string)` from `*wrapper-primitives*` in `runtime.lisp`

## 3. Remove from WASM primitive dispatch

- [x] 3.1 Remove ID 30 dispatch case from `$apply-primitive` in `runtime.wat`
- [x] 3.2 Keep `$prim-number-to-string` as internal function (still called by `$write-to-string-impl` and `$display-to-port`)

## 4. Update primitives.def

- [x] 4.1 Change `number->string` (ID 30) platform from `core` to `ece`

## 5. Rebuild and test

- [x] 5.1 Run `make bootstrap` pass 1 (ECE definition + host primitives still present) — generates new .ecec files
- [x] 5.2 Apply CL and WASM host removals (tasks 2 + 3)
- [x] 5.3 Run `make bootstrap` pass 2 (verify host primitives no longer needed)
- [x] 5.4 Run CL test suite (`make test`) — all tests pass
- [x] 5.5 Rebuild WASM (`make wasm`) and run WASM test suite (`make test-wasm`) — 446 passed, 0 failed (required regenerating primitives.json — truncate/floor were missing)
- [x] 5.6 Verify `gensym` still works on both platforms (depends on `number->string`) — confirmed via test suites
