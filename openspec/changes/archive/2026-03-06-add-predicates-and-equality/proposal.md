## Why

The evaluator lacks basic type predicates and equality operations that are fundamental to any Lisp. Users can't test whether a value is a number, string, or symbol, and have no way to compare structures for deep equality. These are essential building blocks for writing non-trivial programs.

## What Changes

- Add type predicates: `number?`, `string?`, `symbol?`, `boolean?`, `zero?`
- Add equality primitives: `eq?` (identity), `equal?` (structural)
- Add numeric utilities: `modulo`, `abs`, `min`, `max`, `even?`, `odd?`, `positive?`, `negative?`

## Capabilities

### New Capabilities
- `predicates-and-equality`: Type predicates, equality primitives, and numeric utilities

### Modified Capabilities

## Impact

- `src/main.lisp`: Add new primitives to `*primitive-procedure-names*` and `*primitive-procedure-objects*`, export new symbols
- `tests/main.lisp`: Add tests for all new primitives
