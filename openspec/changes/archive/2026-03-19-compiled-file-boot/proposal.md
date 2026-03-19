## Why

ECE's bootstrap image (`ece.image`) is a monolithic binary blob containing the entire instruction vector, label table, environment, macro table, and procedure names. This image architecture created a cascade of complexity: binary serialization (~800 lines of CL), dead-code compaction (462 lines of ECE), compilation spaces to split the blob for native compilation, and multi-space serialization to persist them. Each layer added machinery to manage the blob, and the compilation-spaces change hit a wall because the image's compiled code has hardwired function references that can't be intercepted from CL.

Replacing the image with per-file compiled units (`.ecec` files) eliminates all this machinery. Each `.scm` file compiles to a `.ecec` file containing serialized register machine instructions. Boot loads these files in order. The `.ecec` files are checked into the repo as the bootstrap, like SBCL's FASLs. The register machine instruction set stays exactly as-is — only the packaging changes.

## What Changes

- **Per-file compiled boot**: Boot loads `prelude.ecec`, `compiler.ecec`, `reader.ecec`, `assembler.ecec` in order instead of restoring a monolithic image blob. Each `.ecec` file creates a named space (symbol) and populates it with register machine instructions.
- **Symbol space IDs**: Space IDs become symbols (`prelude`, `compiler`, `my-game`) instead of integers. Procedure entries become `(prelude . 4523)`. Continuations capture these, making them human-readable and stable across rebuilds.
- **`compile-file` / `load-compiled` as primary build mechanism**: compilation-unit.scm's existing `compile-file` and `load-compiled` become the standard way to build and boot. `compile-file` handles macros at compile time.
- **BREAKING: Remove `save-image!` / `load-image!`**: No more image save/load. The "image" is the collection of `.ecec` files.
- **BREAKING: Remove compaction.scm**: Dead-code compaction was only needed for the monolithic image. With per-file units, unreachable code stays in the file — it's small and harmless.
- **BREAKING: Remove binary serializer/deserializer**: The ~800 lines of binary image format code in runtime.lisp goes away. `.ecec` files use s-expression serialization (already implemented in compilation-unit.scm).
- **Two-pass bootstrap in Makefile**: `make bootstrap` boots from existing `.ecec` files, then re-compiles all `.scm` → `.ecec`. The `.ecec` files are checked into `bootstrap/`.

## Capabilities

### New Capabilities
- `compiled-file-boot`: Boot sequence that loads `.ecec` files in order instead of restoring an image. Includes the CL-side boot loader, the Makefile targets, and the `.ecec` file layout in `bootstrap/`.
- `symbol-space-id`: Space IDs are symbols instead of integers. Addresses are `(symbol . local-pc)`. Includes changes to make-compiled-procedure, capture-continuation, the executor's space switch, and the space registry (keyed by symbol).

### Modified Capabilities
- `compile-file`: Updated to target a named space (symbol) per file. The `.ecec` format may need to include metadata (space name, macro registrations).
- `instruction-executor`: Space switch uses symbol comparison (`eq`) instead of integer comparison (`eql`). `*executing-space-id*` becomes a symbol.
- `load-file`: `(load "file.scm")` creates a named space from the filename and compiles into it.

## Impact

- **`src/runtime.lisp`**: Remove binary serializer/deserializer (~800 lines), remove flat-image serializer, remove `ece-save-image`/`ece-load-image`, change space registry from integer-indexed vector to symbol-keyed table, change `*executing-space-id*` and `*current-space-id*` from integers to symbols, add CL-side boot loader that loads `.ecec` files.
- **`src/compaction.scm`**: Removed entirely.
- **`src/compilation-unit.scm`**: Updated `compile-file` to include space name metadata and macro registration. Updated `load-compiled` to create named spaces.
- **`src/assembler.scm`**: `load` creates symbol-named spaces. `ece-assemble-into-global` uses symbol space IDs.
- **`bootstrap/`**: Directory changes from single `ece.image` to per-file `prelude.ecec`, `compiler.ecec`, `reader.ecec`, `assembler.ecec`, `compilation-unit.ecec`.
- **`Makefile`**: `make image` becomes `make bootstrap` (two-pass: boot from .ecec, re-compile .scm → .ecec). `make test` and `make repl` boot from `.ecec` files.
- **`ece.asd`**: May need update if codegen-cl.lisp dependencies change.
- **Continuation serialization**: Unaffected — continuations capture `(symbol . pc)` addresses which are serializable. IF save/load is a separate future concern.
