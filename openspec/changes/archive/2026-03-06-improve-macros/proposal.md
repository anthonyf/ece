## Why

The `cond` macro only supports single-expression clause bodies, so `(cond ((= 1 1) a b))` ignores `b`. All macro definitions use verbose `(list (quote ...) ...)` construction instead of quasiquote, making them harder to read and verify. Now that nested quasiquote works correctly, the macros should be rewritten to use it.

## What Changes

- Fix `cond` to support multi-expression clause bodies via `(begin ...)`
- Rewrite all macro definitions (`cond`, `let`, `let*`, `and`, `or`, `when`, `unless`) to use quasiquote instead of manual `list`/`cons`/`(quote ...)` construction

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `define-macro`: `cond` requirement updated to support multi-expression clause bodies

## Impact

- `src/main.lisp` — rewrite all 7 macro definitions
- `tests/main.lisp` — add test for multi-expression `cond` clause
