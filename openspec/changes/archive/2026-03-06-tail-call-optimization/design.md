## Context

The ECE evaluator uses an explicit continuation stack (SICP 5.4 style). The `ev-sequence-last-exp` handler restores the caller's saved continuation from the data stack and re-dispatches, which means the last expression in a body does not accumulate stack frames. Empirical testing confirms 1M-iteration tail-recursive loops complete without stack overflow through `if`, `begin`, `cond`, `and`, `or`, `when`, `unless`, `let`, and `let*`.

However, no tests exist to prevent regressions, and ECE lacks `named let` — the idiomatic Scheme construct for writing loops without defining top-level functions.

## Goals / Non-Goals

**Goals:**
- Add tests that verify tail calls in all tail-position contexts execute in bounded stack space
- Add `named let` as a macro: `(let name ((var init) ...) body)` expands to a local recursive function
- Spec the tail-position contract

**Non-Goals:**
- Changing the evaluator's existing TCO mechanism (it already works)
- Adding `do` loops or other iteration constructs
- Guaranteeing tail position in `apply` special form (not standard Scheme requirement)

## Decisions

### Decision: Named let implemented by extending the existing `let` macro
The existing `let` macro checks if the first argument is a symbol (the loop name) vs a list (bindings). When a symbol is detected, expand to `(begin (define (name params...) body...) (name inits...))`. This uses `define` rather than `letrec` since ECE doesn't have `letrec` yet.

Alternative considered: Implement as a separate `named-let` macro. Rejected because Scheme specifies this as part of `let` syntax.

### Decision: TCO tests use iteration count of 1,000,000
This is large enough to overflow any non-TCO stack (default stack is ~1MB, each frame uses at least a few words) while still completing quickly (< 1 second in testing). Tests verify the call completes without error rather than measuring stack depth directly.

## Risks / Trade-offs

- [Named let using `define` pollutes the enclosing scope with the loop name] → Acceptable since ECE doesn't have `letrec`. Can be revisited when `letrec` is added.
- [Large iteration count tests could be slow on some systems] → 1M iterations complete in under 1 second in practice.
