## Context

After the drop-ececb change, a single off-by-one bug (`$ecec-op-id` scanning slots 17-37 instead of 17-38) broke yield/resume. All 329 WASM tests passed because they don't exercise the WAT reader's op-id mapping or the JS↔WASM resume boundary. The fix shipped, but we need tests that would catch this class of bug.

## Goals / Non-Goals

**Goals:**
- If `make test-wasm` passes, the sandbox demos work
- Catch WAT reader instruction-building bugs automatically
- Catch JS↔WASM boundary issues (yield/resume) automatically

**Non-Goals:**
- Browser-based testing (Node.js is already a test dependency)
- Performance testing
- UI testing of the sandbox

## Decisions

### 1. Add missing ECE tests to WASM suite

12 test files are currently CL-only. Files that don't use `try-eval` or CL-specific features get added to `WASM_TEST_SRCS` in the Makefile. Files that use `assert-error` (which needs `try-eval`) may need to be reviewed — some tests within those files may work, others may need to be skipped.

Files to add: test-callcc, test-advanced-continuations, test-dynamic-wind, test-guard, test-eval-string, test-cross-space, test-compilation-units, test-misc.

Files to review: test-errors, test-error-messages (use assert-error extensively — may need a WASM-compatible error test mechanism or selective inclusion).

Files to skip: test-file-io (uses CL file I/O), test-serialization (uses save/load-continuation).

### 2. Integration tests in wasm/test.js

Add a section to `wasm/test.js` that runs AFTER bootstrap but BEFORE the ECE test suite. These are Node.js tests that exercise the JS↔WASM boundary:

```
// After bootstrap, before ECE tests:
runIntegrationTests(w, envH);
```

Tests:
- **yield-single**: eval `(begin (define (f) (display "A") (yield) (display "B")) (f))`, check output "A", resume via `call_ece_proc`, check output "AB"
- **yield-multi**: eval a counter loop with yield, resume 3 times, verify counter increments
- **op-id-check**: call `w.check_op_id(symHandle)` for all 22 ops, verify none return -1

Integration test failures are reported alongside ECE test results and cause `make test-wasm` to fail.

### 3. WAT exports for validation

Add to `runtime.wat`:

**`check_op_id(sym-handle) → i32`**: Given a symbol handle, run it through `$ecec-op-id` and return the result. Returns -1 for unrecognized symbols. Used by the op-id exhaustive test.

**`validate_space(space-id) → i32`**: Scan all instructions in a space. For each instruction, verify:
- opcode is 0-6
- For assign-op (b=3), test (op=1), perform (op=6): $c (op-id) is 0-21
- For branch (op=2), goto-label (op=3, b=0), assign-label (op=0, b=2): $c is in 0..len
- For label-referencing instructions: $val is nil (not a symbol)
Returns 0 on success, or the PC of the first invalid instruction.

These are small functions (~30 lines each). They exist in the WASM binary but are only called during tests.

### 4. Test flow

```
make test-wasm
  │
  ├── Compile ECE tests to .ecec
  ├── Boot WASM + load bootstrap via WAT reader
  ├── Run integration tests (yield, op-ids, validate_space)  ← NEW
  ├── Load + run ECE test suite (now ~370+ tests)            ← EXPANDED
  └── Report results, exit non-zero on any failure
```

## Risks / Trade-offs

- **test-errors / test-error-messages**: These use `assert-error` which requires `try-eval` (a CL-only primitive). Options: (a) skip them entirely, (b) implement a WASM-compatible error trapping mechanism, (c) include only the tests that don't use `assert-error`. Option (a) is simplest for now.
- **Binary size**: Two small WAT exports add negligible code (~60 lines).
- **Test time**: Validation scan of ~57K instructions adds microseconds. Integration tests add ~100ms. Total test time stays under 3 seconds.
