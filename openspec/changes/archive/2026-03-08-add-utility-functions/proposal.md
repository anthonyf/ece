## Why

ECE is missing common utility functions for strings and hash tables. `string-contains?` and `string-join` complement the existing `string-split`, and `hash-values` complements `hash-keys`.

## What Changes

- Add `string-contains?` primitive — test if a string contains a substring
- Add `string-join` primitive — join a list of strings with a separator
- Add `hash-values` primitive — return list of values in a hash table

## Capabilities

### New Capabilities
- `string-search`: `string-contains?` and `string-join` functions
- `hash-values`: `hash-values` function for hash tables

### Modified Capabilities

None.

## Impact

- `src/ece.lisp`: Add three new primitives, add exports
- `tests/ece.lisp`: Add tests for all three functions
