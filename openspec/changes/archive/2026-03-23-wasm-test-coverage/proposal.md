## Why

The drop-ececb change introduced a yield/resume bug that passed all 329 WASM tests. The root cause — an off-by-one in the WAT reader's op-id scan — was invisible because: (1) 12 test files including call/cc and dynamic-wind are excluded from the WASM suite, (2) no test exercises the JS↔WASM boundary (yield, call_ece_proc resume), and (3) no test validates the WAT reader's instruction output. The goal is to reach full confidence that if `make test-wasm` passes, the sandbox works.

## What Changes

- Add 12 missing ECE test files to the WASM test suite (test-callcc, test-advanced-continuations, test-dynamic-wind, test-guard, test-eval-string, test-cross-space, test-compilation-units, test-errors, test-error-messages, test-misc, test-file-io, test-serialization)
- Add yield/resume integration tests in `wasm/test.js` that test the JS↔WASM round-trip: eval a program with `(yield)`, verify continuation exists, call `call_ece_proc` to resume, verify multi-frame works
- Add a WAT-exported `validate_spaces` function that scans all loaded instructions and checks structural integrity (op-ids in range, label PCs valid)
- Add an op-id exhaustive check in `wasm/test.js` that verifies all 22 operation names resolve to correct op-ids via a WAT export
- All tests run via `make test-wasm`

## Capabilities

### New Capabilities

- `wasm-integration-tests`: Node.js tests for JS↔WASM boundary (yield/resume, eval-string round-trip)
- `wat-reader-validation`: WAT exports and tests for instruction structural integrity and op-id correctness

### Modified Capabilities

## Impact

- `Makefile`: Add missing test files to WASM_TEST_SRCS
- `wasm/test.js`: Add integration test section (yield/resume, op-id check, validation call)
- `wasm/runtime.wat`: Add `validate_spaces` and `check_op_id` exports (test-only, small)
- Test count increases from 329 to ~370+ (12 more ECE test files + integration tests)
