## Approach

Change the named-let macro to expand to a letrec-style pattern instead of `begin`+`define`. This is a one-line change in the macro definition.

## Current Expansion

```scheme
(let name ((var init) ...) body...)
→ (begin (define (name var...) body...) (name init...))
```

The `define` is only hoisted by the compiler when this `begin` is at the top of a lambda body. When nested (e.g., inside a `string-append` argument), the define falls through to runtime `define-variable!` → `$frame-append`.

## New Expansion

```scheme
(let name ((var init) ...) body...)
→ (letrec ((name (lambda (var...) body...))) (name init...))
```

Which the `letrec` macro further expands to:

```scheme
→ (let ((name ())) (set! name (lambda (var...) body...)) (name init...))
→ ((lambda (name) (set! name (lambda (var...) body...)) (name init...)) ())
```

In this form, `name` is a lambda parameter — always in the lexical environment. The compiler generates `lexical-ref`/`lexical-set!` for it. No `define-variable!` is ever needed.

## Why This Works

- `name` as a lambda parameter is always hoisted (it's a param, not an internal define)
- `set!` (recognized as both `set` and `set!` by `mc-assignment?`) compiles to `lexical-set!` when the variable is in the lexical env
- The recursive call `(name init...)` uses `lexical-ref` to look up `name`
- No `frame-append` is ever triggered
- TCO is preserved: the body's tail calls still compile to gotos

## Key Decision

**Letrec over fixing `mc-extract-define-names`**: Making `mc-extract-define-names` descend into all expression contexts (not just `begin`/`if`) would be more invasive and could have unintended side effects (hoisting defines from contexts where they shouldn't be hoisted, like conditional branches). Changing the macro expansion is surgical and correct.

## Risks

- `letrec` depends on the `let` macro (which we're modifying). The letrec expansion must NOT trigger the named-let path. This is safe because `letrec` expands to regular `let` (with a list of bindings, not a symbol as the first argument).
- The `()` initial value for `name` is briefly visible before `set!` — if `name` is somehow called before the `set!`, it would fail. This matches standard letrec semantics and is the same behavior as before (the old `define` also had the function undefined until the define executed).
