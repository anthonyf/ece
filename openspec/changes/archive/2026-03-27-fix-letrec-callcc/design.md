## Context

Current letrec expansion:
```scheme
(let ((x ()) (y ()))
  (set x init-x)    ;; C1 captured here; x set immediately
  (set y init-y)    ;; C2 captured here; y set immediately
  body...)
```

When C2 is invoked, execution resumes at `(set y ...)`. The `(set x init-x)` is NOT re-executed, so `x` keeps whatever value it was mutated to.

## Goals / Non-Goals

**Goals:**
- Fix letrec so that resuming a continuation captured during any initializer re-assigns ALL variables from their init values
- Pass pitfall test 1.1 (expected result: 0)

**Non-Goals:**
- Full R6RS letrec* semantics (sequential evaluation with earlier bindings visible)

## Decisions

### Use lambda-argument evaluation for init values

New expansion:
```scheme
(let ((x ()) (y ()))
  ((lambda (tmp-x tmp-y)
     (set! x tmp-x) (set! y tmp-y)
     body...)
   init-x init-y))
```

Init values are evaluated as lambda arguments (OUTSIDE the lambda body). When C2 resumes:
1. `init-y` re-evaluates to 0
2. The lambda is re-entered with `(tmp-x=0, tmp-y=0)` — tmp-x was already evaluated and preserved in the continuation's argument list
3. `(set! x 0)` and `(set! y 0)` both execute — variables reset
4. Body evaluates with fresh values

This is the standard R5RS letrec expansion used by conformant implementations.

### Helper function for zipping vars and tmps

ECE's `map` only takes one list. A helper `letrec-make-sets` walks two lists in parallel to build `(set! var tmp)` forms. Defined before the `letrec` macro in the prelude.

## Risks / Trade-offs

**[Extra lambda wrapper]** → Each letrec now creates an additional lambda call. Mitigation: negligible cost; the lambda is immediately applied and the compiler can optimize it.

**[Existing letrec usage]** → All current letrec usage should be unaffected since the new expansion is semantically equivalent for non-continuation cases. The only difference is when continuations are captured during initializers.
