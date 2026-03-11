## Why

`eval` is not available to ECE user code, even though all the machinery exists (`mc-compile-and-go`). Additionally, macro expansion in the ECE compiler (`compiler.scm`) delegates back to CL's `expand-macro-at-compile-time` via a primitive call, meaning the CL compiler's `evaluate` function is still required at runtime. Self-hosting macro expansion removes this dependency, making the CL compiler truly dead code after bootstrap.

## What Changes

- Define `eval` in ECE as a wrapper around `mc-compile-and-go`, available to user code
- Rewrite `mc-expand-macro-at-compile-time` in `compiler.scm` to expand macros directly using `mc-compile-and-go` instead of delegating to the CL `expand-macro` primitive
- Add tests for `eval` and verify macro expansion still works correctly
- The CL `expand-macro-at-compile-time` function and `expand-macro` primitive remain for bootstrap but are no longer called after the ECE compiler loads

## Capabilities

### New Capabilities
- `eval-primitive`: `eval` exposed to ECE code for runtime evaluation of expressions

### Modified Capabilities
- `metacircular-compiler`: Macro expansion is self-hosted — `mc-expand-macro-at-compile-time` uses ECE's own compile-and-go instead of CL primitive

## Impact

- `src/compiler.scm` — rewrite `mc-expand-macro-at-compile-time`, add `eval` definition
- `tests/ece.lisp` — add tests for `eval` and macro expansion verification
- No breaking changes — existing macro definitions and expansions continue to work identically
