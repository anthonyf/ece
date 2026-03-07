## Why

Primitives are currently stored as `(primitive #<FUNCTION>)` — opaque CL function objects. This means continuations captured by `call/cc` contain non-serializable data, preventing save/restore of game state to disk. Storing primitives by symbol name instead makes everything on the evaluator's stack a pure s-expression, enabling future serialization of continuations via CL's `*print-circle*`.

## What Changes

- Change primitive storage from `(primitive #<FUNCTION>)` to `(primitive SYMBOL)`
- Update `*primitive-procedure-objects*` to store CL function symbols instead of function objects
- Update dolist registrations to store symbols instead of function references
- Update `:primitive-apply` to resolve symbol to function via `symbol-function` at call time
- All existing behavior preserved — this is a pure internal refactor

## Capabilities

### New Capabilities

### Modified Capabilities
- `primitive-proc-tests`: Primitive apply now resolves symbols at call time instead of storing function objects

## Impact

- `src/main.lisp`: Modify primitive storage format and apply dispatch
- `tests/main.lisp`: All existing tests must continue to pass unchanged
