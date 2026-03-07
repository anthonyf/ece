## Why

The `apply` special form already achieves TCO in tail position (`ev-apply-dispatch` restores the caller's conts/env before jumping to `apply-dispatch`), but there is no test proving this. The existing TCO test suite covers `if`, `begin`, `cond`, `and`, `or`, `when`, `unless`, `let`, and `let*` but not `apply`.

## What Changes

- Add a regression test verifying `(apply f args)` in tail position completes 1M iterations without stack overflow

## Capabilities

### New Capabilities

### Modified Capabilities
- `tail-call-optimization`: Add scenario for tail-position apply

## Impact

- `tests/main.lisp`: Add one test case to `test-tail-call-optimization`
