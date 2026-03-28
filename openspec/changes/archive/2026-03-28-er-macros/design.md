## Context

Gensym hygiene renames INTRODUCED bindings (new variables in let/lambda) but doesn't protect FREE variables in templates. When a user shadows `+` and a macro template references `+`, the expansion uses the user's `+`, not the global one.

## Goals / Non-Goals

**Goals:**
- Free variables in `syntax-rules` templates resolve to their definition-site bindings
- Pass pitfall test 3.1: `(let-syntax ((foo (syntax-rules () ((_ e) (+ e 1))))) (let ((+ *)) (foo 3)))` → 4
- Add `er-macro-transformer` for advanced macro authors who want explicit renaming control

**Non-Goals:**
- Capturing LEXICAL bindings at definition site (only global bindings for now — covers all practical cases)
- Replacing `define-macro` (it stays as the unhygienic escape hatch)

## Decisions

### 1. Add `%global-ref` compiler special form

`(%global-ref name)` compiles to a direct `lookup-variable-value` for `name`, bypassing lexical scope. This is the primitive that makes renamed symbols work.

```scheme
;; In template: (+ expr 1)
;; After hygiene: (%global-ref +) expr 1
;; Even if user shadows +, (%global-ref +) resolves to the global +
```

Compiler implementation: same as `mc-compile-variable` but skips `mc-find-variable` and always emits `lookup-variable-value`.

### 2. Wrap free variables in syntax-rules templates

In `syntax-instantiate`, when a symbol is:
- NOT a pattern variable
- NOT in the rename table (introduced binder)
- A plain symbol (not `_`, not a literal)

Wrap it in `(%global-ref sym)` instead of emitting the bare symbol. This ensures all free references in the template resolve globally.

Exception: don't wrap symbols that are the CAR of a form and are special forms or macros (like `if`, `let`, `begin`, `set!`) — these need to be recognized by the compiler as keywords, not wrapped.

Actually, simpler: wrap ALL non-pattern-variable symbols. The compiler's special form dispatch happens before variable compilation, so `(%global-ref if)` would never be reached — the form `(if ...)` is recognized by its CAR, and `%global-ref` only appears in variable position.

Wait — if the template has `(+ expr 1)`, this becomes `((%global-ref +) expr 1)`. The CAR is `(%global-ref +)`, a pair. The compiler won't recognize this as a special form (CAR is not a symbol). It falls through to application, which compiles `(%global-ref +)` as the operator — that's correct! It looks up the global `+` and calls it.

### 3. er-macro-transformer (future)

For this change, the `%global-ref` approach is sufficient. A full `er-macro-transformer` can be added later as sugar:

```scheme
(er-macro-transformer
  (lambda (expr rename compare)
    `(,(rename '+) ,(cadr expr) 1)))
```

Where `(rename '+)` produces `(%global-ref +)`. This is a clean extension point but not needed to pass the test.

## Risks / Trade-offs

**[%global-ref only captures globals]** → If a macro is defined inside a `let` and its template references the let-bound variable, `%global-ref` would look it up globally (wrong). Mitigation: this is extremely rare. All standard identifiers are global. Full lexical capture needs ER macros with environment snapshots — a future enhancement.

**[Performance]** → Every free symbol in every syntax-rules template now generates an extra `%global-ref` wrapper. Mitigation: the wrapper compiles to the same `lookup-variable-value` instruction — just skips the lexical check, which is a no-op for globals anyway.
