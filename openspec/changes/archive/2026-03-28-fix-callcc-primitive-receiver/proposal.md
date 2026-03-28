## Why

`(call/cc list)` crashes — passing a primitive directly as the receiver to `call/cc` fails with a type error. `(call/cc (lambda (k) (list k)))` works fine. This is because `%raw-call/cc` in the compiler assumes the receiver is a compiled procedure when applying it, but primitives have a different calling convention.

## What Changes

- Fix the compiler's `%raw-call/cc` handler to support primitive receivers, not just compiled procedures
- No new features — compiler bug fix

## Capabilities

### New Capabilities
_(none)_

### Modified Capabilities
_(none)_

## Impact
- **compiler.scm** or **runtime.lisp**: Fix in the callcc instruction handler
