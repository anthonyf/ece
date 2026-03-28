## 1. Investigate

- [x] 1.1 Read `mc-compile-callcc` in compiler.scm to understand how `%raw-call/cc` is compiled.
- [x] 1.2 Read the executor's callcc branch in runtime.lisp to understand how the receiver is applied.
- [x] 1.3 Identify why primitives fail — find the exact instruction that assumes compiled procedure.

## 2. Fix

- [x] 2.1 Fix the callcc handler to dispatch correctly for primitive vs compiled procedure receivers.
- [x] 2.2 Run `make bootstrap` TWICE to regenerate .ecec files (first pass compiles new compiler, second pass uses it).

## 3. Verify

- [x] 3.1 Verify `(call/cc list)` returns a list containing a continuation.
- [x] 3.2 Verify `(call/cc (lambda (k) (list k)))` still works (no regression).
- [x] 3.3 Run `make test-conformance` — confirm no new failures.
- [x] 3.4 Verify existing ECE tests still pass (0 failures).
