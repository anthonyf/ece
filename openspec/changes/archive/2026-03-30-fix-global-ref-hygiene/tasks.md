## 1. Add lookup-global-variable to CL runtime

- [x] 1.1 Add `lookup-global-variable` function to `runtime.lisp` that calls `lookup-variable-value` with `*global-env*`
- [x] 1.2 Register `lookup-global-variable` in `get-operation` dispatch table

## 2. Add lookup-global-variable to WASM runtime

- [x] 2.1 Add op-id 23 dispatch case in WASM executor (`$execute` function) that calls `$lookup-variable-value` with `$global-env`
- [x] 2.2 Add `lookup-global-variable` to `wasm/test.js` op-id validation array

## 3. Update compiler

- [x] 3.1 Change `mc-compile-global-ref` in `src/compiler.scm` to emit `(op lookup-global-variable) (const name)` instead of `(op lookup-variable-value) (const name) (reg env)`

## 4. Bootstrap and test

- [x] 4.1 Clear FASL cache and run `make bootstrap` pass 1
- [x] 4.2 Clear FASL cache and run `make bootstrap` pass 2
- [x] 4.3 Run `make test` — all CL tests pass (exit 0)
- [x] 4.4 Run `make wasm && make test-wasm` — hygiene tests pass on WASM (remaining FAILs are pre-existing round/TCO issues)
