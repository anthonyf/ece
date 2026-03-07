## Context

ECE has `let` (parallel bindings, including named form) and `let*` (sequential bindings), but no `letrec` for recursive/mutually recursive local bindings. The macro system and `set` special form are already available.

## Goals / Non-Goals

**Goals:**
- Add `letrec` as a macro
- Support single recursive and mutually recursive bindings

**Non-Goals:**
- Adding `letrec*` (sequential evaluation order for init expressions)
- Checking for invalid forward references in init expressions

## Decisions

### Decision: Expand `letrec` to `let` + `set`
`(letrec ((x init-x) (y init-y)) body)` expands to:
```scheme
(let ((x '()) (y '()))
  (set x init-x)
  (set y init-y)
  body...)
```
This is the standard R5RS implementation strategy. The `let` creates the bindings (initialized to `'()`), then `set` assigns the real values in an environment where all names are already visible — enabling mutual recursion.

Alternative considered: Using internal `define`. Rejected because `define` in ECE adds to the current frame, which is what `let` already does, and the `let` + `set` approach is the canonical Scheme expansion.

## Risks / Trade-offs

- [Init expressions can observe uninitialized `'()` values if they reference other bindings eagerly] → This matches R5RS behavior; init expressions should be lambdas for recursive bindings.
