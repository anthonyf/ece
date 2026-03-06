## 1. Core Macro Infrastructure

- [x] 1.1 Add `define-macro-p` predicate and add `define-macro` to `*special-forms*`
- [x] 1.2 Add `ev-define-macro` handler that evaluates a lambda-like form and stores it with `(macro params body env)` tag
- [x] 1.3 Add macro detection in `ev-appl-did-operator` — when `proc` is `(macro ...)`, push `:macro-apply` instead of entering operand loop
- [x] 1.4 Add `:macro-apply` handler that extends environment with unevaluated operands and evaluates macro body
- [x] 1.5 Add `:macro-apply-result` handler that takes `val` (expanded form) and re-dispatches it as `expr`

## 2. Standard Derived Forms

- [x] 2.1 Define `cond` macro via `evaluate` at load time (expands to nested `if`)
- [x] 2.2 Define `let` macro via `evaluate` at load time (expands to lambda application)
- [x] 2.3 Define `let*` macro via `evaluate` at load time (expands to nested `let`)
- [x] 2.4 Define `and` macro via `evaluate` at load time (expands to nested `if`)
- [x] 2.5 Define `or` macro via `evaluate` at load time (expands to nested `if`)
- [x] 2.6 Define `when` and `unless` macros via `evaluate` at load time

## 3. Tests

- [x] 3.1 Add tests for `define-macro` core functionality (definition, unevaluated operands, multi-body)
- [x] 3.2 Add tests for `cond`, `let`, `let*`, `and`, `or`, `when`, `unless`
