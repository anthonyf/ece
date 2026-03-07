## Context

Current `or` macro:
```scheme
(define-macro (or . args)
  (if (null? args) '()
    (if (null? (cdr args)) (car args)
      (list 'if (car args) (car args) (cons 'or (cdr args))))))
```

This expands `(or x y)` into `(if x x (or y))`, evaluating `x` twice when truthy. The fix requires a temp variable: `(let ((t x)) (if t t (or y)))`, but `t` must be a unique symbol to avoid capturing user variables.

## Goals / Non-Goals

**Goals:**
- Add `gensym` primitive so macros can generate hygienic temp variables
- Fix `or` to evaluate each argument exactly once
- Export `gensym` for use in user-defined macros

**Non-Goals:**
- Full hygienic macro system (`syntax-rules`) — `gensym` is the CL-style solution
- Fixing `and` — `and` doesn't have the double-eval bug (it only returns the last value, and short-circuits on false without re-evaluating)

## Decisions

### Decision: `gensym` as a CL-delegating primitive
Implement `gensym` by delegating to CL's `gensym`. This produces uninterned symbols that can never conflict with user code. Register it the same way as I/O primitives (custom wrapper in the `dolist` block).

**Alternative considered:** ECE-level counter-based gensym. Rejected because CL's `gensym` already produces guaranteed-unique uninterned symbols.

### Decision: Fix `or` using `let` + `gensym` at macro expansion time
The `or` macro will call `gensym` during expansion to get a fresh temp variable name, then expand to a `let` that binds the first arg to that temp before testing it:

```scheme
(define-macro (or . args)
  (if (null? args) '()
    (if (null? (cdr args)) (car args)
      (let ((temp (gensym)))
        (list 'let (list (list temp (car args)))
              (list 'if temp temp (cons 'or (cdr args))))))))
```

This evaluates each argument exactly once.

## Risks / Trade-offs

- [Generated symbols are unreadable in debug output] → Acceptable trade-off; same as CL behavior. Users won't see these unless debugging macro expansions.
