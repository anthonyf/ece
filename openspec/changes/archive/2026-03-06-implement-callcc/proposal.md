## Why

`call/cc` (call-with-current-continuation) is the fundamental control flow primitive that enables non-local exits, exceptions, coroutines, and other advanced control patterns. The evaluator already has a stubbed `:ev-callcc` handler with pseudocode comments outlining the approach. Since the evaluator uses an explicit continuation stack and data stack, capturing and restoring continuations is naturally expressible — making this a good time to implement it.

## What Changes

- Add `call/cc` as a special form with syntax `(call/cc <receiver>)`
- Add `callcc-p` predicate and dispatch clause
- Implement `:ev-callcc` to capture the current continuation (stack + conts snapshot) and evaluate the receiver
- Add `:ev-callcc-apply` to apply the evaluated receiver to the captured continuation
- Add `continuation` as a new procedure type recognized by `:apply-dispatch`
- Add `:continuation-apply` handler that restores captured state and sets val
- Add comprehensive tests

## Capabilities

### New Capabilities
- `callcc-special-form`: Implementation and tests for call/cc

### Modified Capabilities

## Impact

- `src/main.lisp`: New predicate, dispatch clause, continuation handlers, new procedure type in apply-dispatch
- `tests/main.lisp`: New test definitions for call/cc
- `*special-forms*` list updated to include `call/cc`
