## Why

The evaluator supports all core special forms but has no way to define new syntax. `define-macro` enables CL-style unhygienic macros — functions that operate on unevaluated s-expressions and return transformed code. This unlocks `cond`, `let`, `let*`, `and`, `or`, `when`, `unless`, and user-defined syntax without modifying the evaluator.

## What Changes

- Add `define-macro` special form that stores a transformer function in the environment with a `(macro params body env)` tag
- Add macro expansion in `ev-dispatch`: when the `car` of an application resolves to a `(macro ...)` value, call the transformer with unevaluated operands, then re-dispatch on the expanded result
- Define standard derived forms (`cond`, `let`, `let*`, `and`, `or`, `when`, `unless`) using `define-macro`

## Capabilities

### New Capabilities
- `define-macro`: CL-style macro definition and expansion

### Modified Capabilities

## Impact

- `src/main.lisp`: Add `define-macro-p` predicate, `ev-define-macro` handler, macro expansion in dispatch, define standard macros
- `tests/main.lisp`: Add tests for define-macro and derived forms
