## Context

`extend-environment` creates frames from parallel lists of variable names and values: `(cons '(x y) '(1 2))`. It assumes `vars` is a proper list. For rest parameters, the parameter list is a dotted pair like `(x y . rest)`, which in CL is the improper list `(x y . rest)`.

`compound-apply` calls `(extend-environment unev (nreverse argl) env)` where `unev` is the parameter list from the procedure object. This is the single point where parameters get bound to arguments.

## Goals / Non-Goals

**Goals:**
- Support `(lambda (x y . rest) ...)` where `rest` captures remaining arguments as a list
- Support `(define (f x . rest) ...)` shorthand
- Work with zero rest arguments: `(lambda (x . rest) x)` called with one arg binds `rest` to `nil`

**Non-Goals:**
- Rest-only parameters like `(lambda args ...)` (a symbol instead of a list) — could be added later but not needed now
- Keyword arguments or destructuring

## Decisions

**Modify `extend-environment` to handle dotted parameter lists**: Rather than adding a separate pre-processing step, `extend-environment` will walk the `vars` and `vals` lists together. When it encounters a non-nil atom in the `cdr` of `vars` (the rest parameter name), it binds that name to the remaining `vals` as a list.

This keeps the change localized to one function. The alternative — normalizing the parameter list in `make-procedure` or `compound-apply` — would spread the logic across multiple places.

**Dotted pair detection via `listp` check**: When walking `vars`, if `(cdr vars)` is not a list (i.e., it's an atom like `rest`), we've hit the rest parameter. Bind `(cdr vars)` to the remaining `vals`.

**No changes to `make-procedure` or `compound-apply`**: The parameter list is stored as-is in the procedure object. `extend-environment` handles the dotted pair transparently.

## Risks / Trade-offs

- [Improper list handling in `lookup-variable-value` and `define-variable!`] → These scan frames using `(car vars)` / `(cdr vars)`. Since `extend-environment` will produce a proper-list frame (it flattens the dotted pair into proper variable/value lists), these functions need no changes.
