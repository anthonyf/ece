## Why

ECE currently has `map` but lacks other essential higher-order functions. `filter`, `reduce`, and `for-each` are fundamental building blocks for list processing in any Lisp. Without them, users must write manual recursive loops for common operations.

## What Changes

- Add `filter` — select elements from a list that satisfy a predicate
- Add `reduce` — fold a list into a single value using a binary function and initial accumulator
- Add `for-each` — apply a procedure to each element for side effects (like `map` but returns nil)

## Capabilities

### New Capabilities
- `higher-order-functions`: filter, reduce, and for-each as built-in procedures

### Modified Capabilities

None.

## Impact

- `src/main.lisp` — new ECE-level function definitions (same pattern as `map`)
- `tests/main.lisp` — new test cases
