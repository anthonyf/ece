## Why

Top-level `(define ...)` appearing late in a large `.ecec` file crashes when the defined function is invoked through a closure (e.g., a test thunk). Direct bare calls at top level work fine. The crash is "illegal cast" in the executor, happening in the test compilation space (not the global env).

Investigation so far:
- The global env names/vals stay perfectly in sync (347/347 after test defines)
- Bare top-level calls to the function work
- Closure-based invocations (via `run-tests` → thunk) crash
- The crash happens in the test space, not the prelude
- Even trivial functions like `(define (my-double x) (+ x x))` trigger it

This blocks adding test helpers to the ECE test suite and causes subtle failures when .ecec files grow large.

## What Changes

- Investigate the crash: why does `lookup-variable-value` or function invocation fail when called from a closure but not from top-level?
- Fix the root cause in the executor or `define-variable!` / `frame-append`
- Add a regression test: late top-level define called from closure thunks

## Capabilities

### New Capabilities
_None_

### Modified Capabilities
_None_ — this is a bug fix with no spec-level behavior change.

## Impact

- `wasm/runtime.wat` — likely fix in `$frame-append`, `$define-variable!`, or the executor's closure handling
- `tests/ece/test-roundtrip.scm` — re-enable tests blocked by this bug
