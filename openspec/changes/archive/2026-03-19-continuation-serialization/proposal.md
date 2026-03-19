## Why

`save-continuation!` and `load-continuation` were removed as collateral damage when the flat-image serializer was deleted during the compiled-file-boot change. These primitives are needed for persisting game state in interactive fiction (Dunge) and for any application that needs to checkpoint and restore ECE program state.

## What Changes

- **Reimplement `save-continuation!`**: Serialize any ECE value to a file as an s-expression. Written in ECE (not CL) to minimize the kernel.
- **Reimplement `load-continuation`**: Deserialize an ECE value from a file using the ECE reader.
- **S-expression format**: Use readable s-expressions with tagged representations for special types (compiled procedures, continuations, hash tables). No custom binary format.
- **Space-qualified addresses**: Compiled procedure entries are now `(symbol . local-pc)` — the serializer must preserve the space symbol.
- **Primitives by name**: Primitive references stored as symbol names (not numeric IDs) for portability across rebuilds.

## Capabilities

### New Capabilities
- `value-serialization`: ECE-side serialization of arbitrary values to s-expression format, handling all ECE data types including compiled procedures with space-qualified addresses, continuations with stack copies, HAMT hash tables, vectors, and primitives stored by name.

### Modified Capabilities
- `save-load`: Restoring the `save-continuation!` and `load-continuation` primitives with updated semantics for the per-space architecture.

## Impact

- **`src/prelude.scm`** or new **`src/serialization.scm`**: ECE-side serializer/deserializer implementation.
- **`src/runtime.lisp`**: Re-register `save-continuation!` and `load-continuation` in `*wrapper-primitives*` (or implement as ECE functions callable via `evaluate`).
- **`primitives.def`**: Restore primitive IDs 104/105 or register as ECE-level functions.
- **`tests/ece.lisp`**: Restore round-trip tests for plain values, hash tables, continuations, compiled procedures.
- **`tests/ece/`**: Add ECE-native serialization tests.
