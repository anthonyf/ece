## Context

All 7 macro definitions currently use manual `(list (quote ...) ...)` construction. Now that quasiquote (including nested quasiquote) works correctly, these should be rewritten for readability. The `cond` macro also has a bug: it uses `(cadr (car clauses))` to extract the clause body, which only captures a single expression.

## Goals / Non-Goals

**Goals:**
- Fix `cond` multi-expression clause bodies using `(cons 'begin (cdr (car clauses)))`
- Rewrite all macros to use quasiquote for clarity
- Preserve identical semantics (all existing tests must still pass)

**Non-Goals:**
- Adding new macro forms (e.g., `letrec`, `case`)
- Changing macro expansion semantics

## Decisions

### Decision: `cond` wraps clause body in `begin`
For multi-expression support, wrap the clause body (everything after the test) in `(begin ...)`. This handles both single and multiple expressions uniformly: `(cond ((test) expr1 expr2))` expands to `(if test (begin expr1 expr2) (cond ...))`.

### Decision: Use quasiquote in all macro definitions
Each macro will be rewritten to use `` ` ``, `,`, and `,@` instead of `list`, `cons`, and `(quote ...)`. This is purely a readability improvement — the expansion semantics are identical.

Note: The `or` macro uses `gensym` at expansion time, so its quasiquote form will contain `,temp` references to the gensym variable bound in the `let` surrounding the quasiquote.

## Risks / Trade-offs

- [Quasiquote rewrites could introduce subtle expansion bugs] → Mitigated by comprehensive existing test suite covering all macros
