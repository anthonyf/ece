## Why

The evaluator has basic list operations (`car`, `cdr`, `cons`, `list`, `null?`) but lacks `map`, `append`, `cadr`, and other utilities needed for writing macro transformers. These are prerequisites for `define-macro`.

## What Changes

- Add `map` as an ECE-defined function (uses rest params and recursion)
- Add `append` as a primitive for splicing lists together
- Add `cadr`, `caddr`, `caar`, `cddr` as primitives for concise list access
- Add `length` as a primitive
- Add `pair?` predicate (true for cons cells)
- Add `apply` as a primitive (calls a procedure with a list of arguments)

## Capabilities

### New Capabilities
- `list-primitives`: Additional list manipulation primitives and map

### Modified Capabilities

## Impact

- `src/main.lisp`: Add new primitives to `*primitive-procedure-names*` / `*primitive-procedure-objects*`, define `map` as ECE function, add `apply` primitive with custom wrapper
- `tests/main.lisp`: Add tests for new primitives
