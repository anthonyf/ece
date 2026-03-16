## Why

CI passes even when tests fail because rove's exit code is always 0, and the `test-error-context` test has been silently broken since the compiler switched to vector-based environment frames. These two bugs hide each other — a broken test behind a broken pipeline.

## What Changes

- **CI workflow**: Replace `asdf:test-system` with a command that checks `rove:run`'s return value and exits non-zero on failure
- **test-error-context**: Fix the "error includes visible environment bindings" subtest to handle vector frames (`#(val ...)`) instead of assuming cons-based frames (`(vars . vals)`)

## Capabilities

### New Capabilities

- `ci-test-exit-code`: CI test runner exits non-zero when any rove test fails

### Modified Capabilities

- `error-context`: The "error includes visible bindings" scenario needs its test updated — the spec's requirement is fine, but the test assumes cons-based frames which no longer exist in the compiler's output

## Impact

- `.github/workflows/test.yml` — CI command changes
- `tests/ece.lisp` — `test-error-context` subtest updated
