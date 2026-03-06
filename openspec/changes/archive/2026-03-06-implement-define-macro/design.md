## Context

The evaluator dispatches on expression type in `ev-dispatch`. Special forms have predicates (`if-p`, `define-p`, etc.) and are listed in `*special-forms*` to prevent `application-p` from matching them. Regular applications go through the operand evaluation loop before `apply-dispatch`.

Macros need a different path: the `car` of an expression looks like a regular application, but if it resolves to a macro, the operands should NOT be evaluated — they're passed raw to the transformer function, and the result is re-dispatched.

## Goals / Non-Goals

**Goals:**
- `define-macro` stores a transformer as `(macro params body env)` in the environment
- Macro expansion happens transparently in `ev-dispatch` — when an application's operator resolves to a macro, expand and re-dispatch
- Define standard derived forms: `cond`, `let`, `let*`, `and`, `or`, `when`, `unless`

**Non-Goals:**
- Hygienic macros (no renaming, no `syntax-rules`)
- `macroexpand` / `macroexpand-1` introspection
- Nested `define-macro` (macros are defined at top level only)

## Decisions

**Macro tag `(macro params body env)`**: Same structure as `(procedure params body env)` but with a different tag. This allows `define-macro` to reuse `ev-define`'s pattern — evaluate a lambda-like expression and store the result. The only difference is the tag.

**Expand in `ev-dispatch` via application path**: Rather than adding a separate `macro-p` predicate (which can't work since macro names aren't statically known), macro expansion happens in the application path. When `ev-appl-did-operator` sees that `proc` is a `(macro ...)`, instead of entering the operand loop, it calls the macro transformer with the unevaluated operands, sets `expr` to the result, and re-dispatches. This is the cleanest integration point because the operator has already been evaluated (so we know it's a macro), and the operands are still unevaluated in `unev`.

**Macro application uses `:macro-apply` handler**: After `ev-appl-did-operator` detects a macro, it pushes `:macro-apply`. This handler applies the macro transformer to the raw operands using `extend-environment` and `ev-sequence` (same as compound-apply), but instead of returning the value, it sets `expr` to the result and re-dispatches. The trick: we need the macro body's return value to become the new `expr`, not the final `val`. So `macro-apply` sets up the body evaluation, and a `macro-apply-result` handler takes `val` (the expanded form) and re-dispatches it.

**Standard macros defined via `evaluate` at load time**: After `evaluate` is defined, call `evaluate` with `define-macro` forms for `cond`, `let`, `let*`, `and`, `or`, `when`, `unless`. Same pattern as the `map` definition.

## Risks / Trade-offs

- [No hygiene — variable capture possible] → Acceptable for the ECE's scope; users must be careful with macro-introduced bindings, same as CL
- [Macros expand at every call, no caching] → Fine for this scale; a future optimization could cache expansions
- [Macro expansion in `ev-appl-did-operator` adds a branch] → Minimal impact; it's a single `eq` check on the proc tag
