## 1. Add runtime_error import

- [x] 1.1 Add `(import "io" "runtime_error" ...)` to runtime.wat
- [x] 1.2 Add `runtime_error(len)` handler to glue.js io object
- [x] 1.3 Add handler to test.js imports
- [x] 1.4 Sandbox uses glue.js io directly — no separate change needed

## 2. Add error signaling infrastructure

- [x] 2.1 Add `$signal-error-sym` helper and `$err-unbound-var` string constant
- [x] 2.2 Unbound variable check deferred — internal lookups (compiler, macro check) rely on null returns. Error should come from ECE-level error system, not WAT-level abort.

## 3. Fix symbol table overflow

- [x] 3.1 Add `$grow-sym-arrays` helper: double arrays and copy
- [x] 3.2 Add bounds check in `$intern` before insertion
- [x] 3.3 Remove stale `$sym-capacity` global (use array.len instead)

## 4. Fix space array overflow

- [x] 4.1 Add bounds check and growth in `$register-space`

## 5. Verification

- [x] 5.1 Run `make test-wasm` — 417 passed, 0 failed
- [x] 5.2 Run `make test` — CL tests pass
- [x] 5.3 Run `make sandbox` — builds successfully
