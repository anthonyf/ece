## Why

The current `map` and `filter` implementations use non-tail-recursive patterns — the recursive call is inside `cons`, so the call stack grows with every list element. On large lists this will exhaust the stack. `reduce` and `for-each` are already tail-recursive.

## What Changes

- Rewrite `map` to use an accumulator and `reverse`, making it fully tail-recursive
- Rewrite `filter` to use the same accumulator + `reverse` pattern
- Add `reverse` as a new primitive procedure and export it

## Capabilities

### New Capabilities
- `reverse`: Primitive procedure that reverses a list

### Modified Capabilities
- `higher-order-functions`: `map` and `filter` updated to be tail-recursive (no behavioral change, only stack usage)
- `list-primitives`: `map` requirement updated to note tail-recursive implementation; `reverse` added

## Impact

- `src/main.lisp`: Add `reverse` primitive, rewrite `map` and `filter` definitions, add export
- `tests/main.lisp`: Add tests for `reverse`, add large-list tests for `map` and `filter` to verify TCO
