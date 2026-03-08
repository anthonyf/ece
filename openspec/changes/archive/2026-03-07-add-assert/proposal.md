## Why

ECE has `error` for signaling failures but no convenient way to assert invariants. `assert` is a standard debugging/validation tool that makes intent clearer than manual `if`/`error` checks.

## What Changes

- Add `assert` macro to the prelude that signals an error when a condition is falsy
- Supports optional custom message: `(assert expr)` or `(assert expr "message")`

## Capabilities

### New Capabilities
- `assert`: Macro for validating conditions, signals error on failure

### Modified Capabilities

None.

## Impact

- `src/prelude.scm`: Add `assert` macro definition
- No changes to `src/ece.lisp` — pure ECE macro using existing `error` primitive
