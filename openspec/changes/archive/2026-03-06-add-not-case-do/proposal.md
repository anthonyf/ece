## Why

ECE lacks `case` and `do`, two standard control/iteration constructs from R5RS Scheme. `case` provides value-based dispatch (like `switch`), and `do` provides general iteration with multiple variables and a termination test. Both can be implemented as macros over existing primitives.

Note: `not` is already a primitive (wrapping `cl:not`) and is tested. No work needed for `not`.

## What Changes

- Add `case` macro: match a key against constant datums, dispatch to the matching clause
- Add `do` macro: general iteration with variable bindings, step expressions, termination test, and optional body
- Export `case` and `do` from the ECE package

## Capabilities

### New Capabilities
- `case-form`: `case` macro for value-based dispatch
- `do-form`: `do` macro for general iteration

### Modified Capabilities

## Impact

- `src/main.lisp`: Add two macro definitions (after existing macros), add exports
- `tests/main.lisp`: Add tests for `case` and `do`
