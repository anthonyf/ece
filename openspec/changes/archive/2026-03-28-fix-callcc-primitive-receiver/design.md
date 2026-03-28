## Context

`%raw-call/cc` captures a continuation and then applies the receiver to it. The application path assumes the receiver is a compiled procedure (using `compiled-procedure-entry` etc). When the receiver is a primitive like `list`, the application uses `apply-primitive-procedure` which has a different calling convention.

## Goals / Non-Goals

**Goals:**
- `(call/cc list)` returns `(continuation)` without crashing
- `(call/cc +)` and other primitive receivers work

**Non-Goals:**
- Fixing complex multi-continuation tests 1.2/1.3 (separate deeper issue)

## Decisions

### Investigate the compiler's callcc codegen

The fix is in how the compiler generates code for `(%raw-call/cc receiver)`. It needs to handle both compiled procedures and primitives as receivers. Look at `mc-compile-callcc` in compiler.scm and the executor's callcc branch in runtime.lisp.

## Risks / Trade-offs

**[Minimal risk]** — Only changes behavior when receiver is a primitive, which was previously broken.
