## Why

ECE has no indexed mutable data structure. Vectors provide O(1) random access and are the standard Scheme complement to linked lists. CL's reader already handles `#(...)` vector literal syntax, so this is primarily about adding primitives and making vectors self-evaluating.

## What Changes

- Make vectors self-evaluating (add `vectorp` check to `self-evaluating-p`)
- Add vector primitives: `vector?`, `make-vector`, `vector`, `vector-length`, `vector-ref`, `vector-set!`, `vector->list`, `list->vector`
- `vector-set!` introduces the first mutable data operation beyond `set!` on variables
- Export all vector symbols from the ECE package

## Capabilities

### New Capabilities
- `vector-ops`: Vector creation, access, mutation, and conversion primitives

### Modified Capabilities

## Impact

- `src/main.lisp`: Add vectorp to self-evaluating-p, add vector primitives and exports
- `tests/main.lisp`: New test cases for vector operations
- No reader changes needed — CL's `#(...)` syntax works automatically
