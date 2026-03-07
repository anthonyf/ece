## Why

The evaluator's explicit continuation stack already achieves tail-call optimization — `ev-sequence-last-exp` restores the caller's continuation without growing the data stack. However, there are no tests proving this, and no spec documenting the tail-position contract. A regression could silently break TCO with no test catching it. Additionally, ECE lacks `named let` (the idiomatic Scheme iteration construct), forcing users to define top-level helper functions for simple loops.

## What Changes

- Add tests verifying TCO works through all tail-position contexts: `if` consequent/alternative, `begin` last expression, `cond` clause body, `and`/`or` last expression, `when`/`unless` body, `let`/`let*` body, and nested combinations
- Add spec documenting tail-position requirements
- Add `named let` macro: `(let loop ((i 0)) (if (< i 10) (loop (+ i 1)) i))`

## Capabilities

### New Capabilities
- `tail-call-optimization`: Spec covering which positions are tail positions and the guarantee that tail calls execute in constant stack space
- `named-let`: Spec for the named let iteration construct

### Modified Capabilities

## Impact

- `src/main.lisp`: Add `named let` macro (modify existing `let` macro to detect named form)
- `tests/main.lisp`: Add TCO verification tests and named let tests
