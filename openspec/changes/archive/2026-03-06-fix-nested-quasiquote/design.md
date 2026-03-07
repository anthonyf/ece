## Context

Current `qq-expand` is a flat walker with no depth tracking:
```lisp
(defun qq-expand (form)
  (cond
    ((null form) '(quote ()))
    ((atom form) (list 'quote form))
    ((eq (car form) 'unquote) (cadr form))
    ((and (consp (car form)) (eq (caar form) 'unquote-splicing))
     (list 'append (cadar form) (qq-expand (cdr form))))
    (t (list 'cons (qq-expand (car form)) (qq-expand (cdr form))))))
```

This fails for nested quasiquote because `unquote` inside an inner `quasiquote` gets evaluated immediately instead of being preserved.

## Goals / Non-Goals

**Goals:**
- Correct nested quasiquote behavior matching R5RS/CL semantics
- Existing (non-nested) quasiquote usage continues to work identically

**Non-Goals:**
- Optimizing the generated cons/append expressions

## Decisions

### Decision: Add depth parameter to `qq-expand`
Add a `depth` parameter (default 0) to `qq-expand`. The `ev-quasiquote` handler calls `(qq-expand (cadr expr) 0)` as before.

Rules:
- `quasiquote` form encountered → increment depth, wrap result in `(list 'quasiquote ...)`
- `unquote` at depth 0 → evaluate (return the expression directly)
- `unquote` at depth > 0 → decrement depth, wrap result in `(list 'unquote ...)`
- `unquote-splicing` at depth 0 → append (existing behavior)
- `unquote-splicing` at depth > 0 → decrement depth, wrap result in `(list 'unquote-splicing ...)`
- Everything else → recurse with same depth

**Alternative considered:** Separate `qq-expand-nested` function. Rejected because depth tracking in a single function is simpler and follows the standard approach (as in CLtL2 and SRFI-72).

## Risks / Trade-offs

- [Deeply nested quasiquotes produce deeply nested cons expressions] → Acceptable; deeply nested quasiquote is rare and this is an educational evaluator.
