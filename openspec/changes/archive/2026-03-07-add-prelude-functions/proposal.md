## Why

The prelude is missing common functional programming utilities that users would otherwise rewrite repeatedly. Adding `any`, `every`, `compose`, `identity`, and `range` rounds out the standard library for typical list processing and function composition patterns.

## What Changes

- Add `any` — returns `#t` if any list element satisfies a predicate
- Add `every` — returns `#t` if all list elements satisfy a predicate
- Add `compose` — returns a function that applies `f` to the result of `g`
- Add `identity` — returns its argument unchanged
- Add `range` — generates a list of integers from 0 to n-1

## Capabilities

### New Capabilities
- `prelude-functions`: Standard utility functions for list predicates, function composition, and list generation

### Modified Capabilities

None.

## Impact

- `src/prelude.scm`: Add 5 function definitions
- No changes to `src/ece.lisp` — all pure ECE functions
