## 1. CL Executor

- [x] 1.1 Add `|halt|` case to instruction dispatch in `execute-instructions` (`src/runtime.lisp` ~line 1698): `(|halt| (go loop-end))`

## 2. Compiler

- [x] 2.1 In `mc-compile-and-go` (`src/compiler.scm` ~line 745), append `(halt)` to the instruction list passed to `assemble-into-global`

## 3. WASM Executor

- [x] 3.1 Add `halt` instruction handling to the WASM `execute-instructions` dispatch loop in `src/wat/runtime.wat` — branch to loop exit

## 4. Testing

- [x] 4.1 Add a test that captures a continuation with `call/cc` in one expression, then invokes it from a subsequent expression, verifying it does not loop infinitely
- [x] 4.2 Run full test suite (`make test`, ECE self-hosted tests, conformance tests, WASM tests) to confirm no regressions
