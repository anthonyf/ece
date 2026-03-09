## Why

ECE currently recompiles the entire prelude on every startup. As the system grows (metacircular compiler, game code), this cost increases. An image system allows dumping the full compiled state — instruction vector, label table, environment, compile-time macros — and restoring it instantly. This is also a prerequisite for the metacircular compiler: bootstrap once with the CL compiler, dump the image, then load runtime + image without needing compiler.lisp at all.

## What Changes

- Store instructions in serializable form (keep `(op name)` alongside or instead of `(op-fn #<function>)`) so the instruction vector can be written to disk
- Add `save-image!` primitive: serializes the global instruction vector, label table, global environment, and compile-time macro table to a file
- Add `load-image!` primitive: deserializes an image file and restores all state, re-resolving operation function pointers
- Add comprehensive tests for round-tripping images: save after compiling code, load into a fresh runtime, verify all definitions and behaviors survive

## Capabilities

### New Capabilities
- `image-serialization`: Save and restore the full ECE compiled state (instruction vector, label table, environment, compile-time macros) to/from disk

### Modified Capabilities
- `instruction-executor`: Instructions must be stored in a serializable form so the instruction vector can be written to disk and re-resolved on load

## Impact

- `src/runtime.lisp`: Modified — serializable instruction storage, `resolve-operations` changes, new `save-image!`/`load-image!` primitives, `get-operation` changes
- `src/compiler.lisp`: Minor — register new primitives in global env
- `src/prelude.scm`: No changes expected
- `tests/ece.lisp`: New test section for image save/load round-tripping
