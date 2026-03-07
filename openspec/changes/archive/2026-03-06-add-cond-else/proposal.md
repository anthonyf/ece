## Why

Writing `(cond ... (t fallback))` works but doesn't communicate intent as clearly as `(cond ... (else fallback))`. Adding `else` support matches Scheme convention while keeping `t` working for CL familiarity.

## What Changes

- Modify the `cond` macro to recognize `else` as the test in the last clause, treating it as always-true
- Both `(cond ... (else expr))` and `(cond ... (t expr))` SHALL work
- Add tests for `else` clause

## Capabilities

### New Capabilities

### Modified Capabilities
- `define-macro`: Add scenario for `cond` with `else` clause

## Impact

- `src/main.lisp`: Modify `cond` macro to check for `else` symbol
- `tests/main.lisp`: Add test for `else` clause
