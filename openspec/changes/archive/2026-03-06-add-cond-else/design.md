## Context

The `cond` macro currently expands clauses to nested `if` expressions. The test expression is always evaluated. Since `t` is self-evaluating in ECE, `(cond (t expr))` already works as a catch-all. Adding `else` is a readability improvement.

## Goals / Non-Goals

**Goals:**
- Recognize `else` as a test in `cond` clauses, expanding to just the body (no conditional)
- Keep `t` working as before

**Non-Goals:**
- Making `else` a general keyword usable outside `cond`

## Decisions

### Decision: Check for `else` in the macro expansion
When the test of a clause is the symbol `else`, expand to just `(begin body...)` instead of `(if else (begin body...) (cond ...))`. This avoids needing `else` to be bound to anything — it's purely a syntactic check in the macro.

## Risks / Trade-offs

- [Users could shadow `else` with a variable binding] → Acceptable; same risk exists in R5RS Scheme with non-hygienic macros.
