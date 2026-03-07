## Why

ECE lacks `letrec`, which means mutually recursive local functions cannot be defined. Users must resort to top-level `define` for patterns like mutually recursive `even?`/`odd?`. This is a core Scheme form that enables important patterns.

## What Changes

- Add `letrec` as a macro that expands to `let` with initial `'()` values followed by `set` for each binding
- Add tests for single recursive binding, mutual recursion, and body in tail position

## Capabilities

### New Capabilities
- `letrec`: Spec for the `letrec` derived form supporting recursive and mutually recursive local bindings

### Modified Capabilities

## Impact

- `src/main.lisp`: Add `letrec` macro definition
- `tests/main.lisp`: Add `letrec` tests
