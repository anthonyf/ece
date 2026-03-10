## Why

Error messages and backtraces from `ece-runtime-error` show compiled procedures as `<compiled-procedure entry=1500>` — a raw PC number that means nothing to the user. The compiler knows the procedure name at `define` time, but this information is discarded. A PC-to-name mapping table would turn opaque entry addresses into readable names like `f` in error output and backtraces.

## What Changes

- Add a `*procedure-name-table*` hash table mapping entry PCs to procedure name symbols
- Emit a `procedure-name` pseudo-instruction from `compile-define` (CL compiler) and `mc-compile-define` (MC compiler) that associates a lambda's entry label with the defined name
- Handle the pseudo-instruction in `assemble-into-global` to populate the table at assembly time
- Update `format-ece-proc` to look up entry PCs in the table for display
- Serialize/restore the name table in image save/load

## Capabilities

### New Capabilities
- `procedure-name-table`: Mapping entry PCs to procedure names at compile time for use in error display and backtraces

### Modified Capabilities
- `error-context`: Error formatting now uses the name table to display procedure names instead of raw PCs
- `image-serialization`: Image save/load includes the procedure name table as a 5th serialized element

## Impact

- `src/compiler.lisp`: `compile-define` emits `procedure-name` pseudo-instruction
- `src/compiler.scm`: `mc-compile-define` emits `procedure-name` pseudo-instruction
- `src/runtime.lisp`: New `*procedure-name-table*` global, `assemble-into-global` handles pseudo-instruction, `format-ece-proc` uses table lookup, `ece-save-image`/`ece-load-image` serialize the table
- **BREAKING**: Image format changes from 4-element to 5-element list. Old images cannot be loaded by new code.
