## 1. Fix load_ecec capacity in runtime.wat

- [x] 1.1 Move `create-space-internal` call from before Phase 1 to after Phase 1, passing `$pc` as the capacity argument instead of `(i32.const 65536)`

## 2. Fix test-wasm failure detection

- [x] 2.1 Fix test.js: read `*test-passes*`/`*test-failures*` from env instead of parsing summary line
- [x] 2.2 Fix test.js: report WASM crashes explicitly in output
- [x] 2.3 Fix Makefile: use `set -o pipefail` so node's exit code propagates through tee pipe
- [x] 2.4 Fix Makefile: remove redundant `grep -q` check

## 3. Add WASM primitive type-error bridging

- [x] 3.1 Add `$error-sentinel` struct type and helper functions (string-concat, all-numbers, prim-name-str, etc.)
- [x] 3.2 Add type guards to `$apply-primitive` for car/cdr, +/-/*/÷, =/</>/, string-length/ref, char->integer, vector-ref
- [x] 3.3 Add sentinel detection in execution loop (assign, test, perform opcodes) that bridges to ECE's `error` function
- [x] 3.4 Handle car/cdr of nil (return nil, matching CL behavior)
- [x] 3.5 Cache `error` symbol via `set_error_sym` export + glue.js registration
- [x] 3.6 Add guard wrapping to wasm-test-runner.scm for error isolation (matching CL test framework)
- [x] 3.7 Skip unbound-variable tests on WASM with `platform-has?` guard (CL-level feature)

## 4. Re-enable test-wasm in CI

- [x] 4.1 Add `test-wasm` to Makefile `test` target
- [x] 4.2 Verify `make test` passes: all suites green, wasm-ece baseline OK (583 >= 490)
