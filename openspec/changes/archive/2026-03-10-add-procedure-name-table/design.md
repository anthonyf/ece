## Context

ECE's `ece-runtime-error` condition (shipped in `add-error-context`) displays compiled procedures as `<compiled-procedure entry=1500>` — a raw PC that is meaningless to the user. The compiler has the procedure name at `compile-define` time but discards it. Both the CL compiler (`compile-define`) and the MC compiler (`mc-compile-define`) know the name being defined and the entry label of the lambda being compiled.

The assembler (`assemble-into-global`) resolves labels to PCs and could populate a mapping table at that point. `format-ece-proc` and backtrace formatting already exist and would consume this table.

## Goals / Non-Goals

**Goals:**
- Map entry PCs to procedure names at compile/assembly time
- Display procedure names in error messages and backtraces
- Work for both the CL compiler and the MC compiler
- Survive image save/load round-trips

**Non-Goals:**
- Naming anonymous lambdas (only `define` forms register names)
- Source location tracking (separate thread)
- Runtime overhead — the table is populated at compile time, only consulted on errors

## Decisions

### 1. Use a pseudo-instruction to pass names from compiler to assembler

**Decision**: `compile-define` and `mc-compile-define` emit a `(procedure-name <label> <name>)` pseudo-instruction in the instruction sequence. `assemble-into-global` recognizes it, resolves the label to a PC, stores the mapping in `*procedure-name-table*`, and does NOT emit it as a real instruction.

**Alternatives considered**:
- **Direct registration from `compile-define`**: The compiler doesn't know the final PC — labels are resolved at assembly time. Would require breaking the compile/assemble separation.
- **Registration at `define-variable!` time**: Would require inspecting the value to check if it's a compiled procedure, and wouldn't work for redefinitions or procedures that are never stored via `define`.
- **Label naming convention**: Labels like `ENTRY42` don't carry the original name. Would require changing `make-label` which affects all label users.

### 2. Serialize the name table as a 5th element in image format

**Decision**: `ece-save-image` serializes `*procedure-name-table*` as an alist appended as the 5th element of the image list. `ece-load-image` restores it. Old 4-element images are not supported.

**Alternatives considered**:
- **Rebuild from instruction source on load**: Pseudo-instructions are not stored in the source vector (they're consumed by the assembler), so there's nothing to rebuild from.
- **Embed in label table**: The label table maps names→PCs; the name table maps PCs→names. Combining them would conflate two different lookup directions.

### 3. Store in a hash table keyed by integer PC

**Decision**: `*procedure-name-table*` is `(make-hash-table)` with integer keys (PCs) and symbol values (names). This gives O(1) lookup from `format-ece-proc`.

## Risks / Trade-offs

- **[Image format breaking change]** Old images cannot be loaded by new code. → Acceptable since image format is not yet stable; no deployed production images exist.
- **[Redefinitions]** If `(define (f ...) ...)` is evaluated twice, two different entry PCs map to `f`. Both entries remain in the table. → Not a problem; each entry PC correctly maps to the name that was active when it was compiled.
- **[MC compiler integration]** `mc-compile-define` must emit the pseudo-instruction as an ECE list, not a CL list. → Use `(list 'procedure-name label variable)` in the Scheme code, which naturally produces ECE lists that `assemble-into-global` can handle.
