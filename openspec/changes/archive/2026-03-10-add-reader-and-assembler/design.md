## Context

ECE currently uses CL's `read` (with a custom readtable) for all parsing and a CL function `assemble-into-global` for assembling compiled instructions. The metacircular compiler (`compiler.scm`) already compiles ECE to register machine instructions in ECE. Moving the reader and assembler to ECE completes the self-hosting story: all "interesting" language infrastructure lives in ECE, with CL reduced to a thin executor + primitives substrate.

The port and character I/O primitives (`read-char`, `peek-char`, `open-input-string`, etc.) were added in the previous change and provide the foundation for the reader. ECE already has hash tables, vectors, and string operations needed by the assembler.

## Goals / Non-Goals

**Goals:**
- Implement a complete s-expression reader in ECE that parses all current ECE syntax
- Implement an assembler in ECE that replaces `assemble-into-global`
- Wire both into the compilation pipeline so they're used for REPL, `load`, and `compile-and-go`
- Keep CL reader/assembler for cold bootstrap (loading reader.scm and assembler.scm themselves)
- Maintain full backward compatibility — same syntax, same behavior

**Non-Goals:**
- Source location tracking (future change, reader is designed to accommodate it)
- Reader macros / extensible reader (future change)
- Removing the CL reader/assembler code (kept for cold bootstrap)
- Changing symbol case convention (stay with upcasing)
- Optimizing reader performance

## Decisions

### Decision 1: Reader architecture — recursive descent with read-char/peek-char

The reader is a recursive descent parser using `read-char` and `peek-char` on ports. The main `ece-scheme-read` function dispatches on the next character:
- Whitespace/comments → skip, recurse
- `(` → read list
- `'` → read quote shorthand
- `` ` `` → read quasiquote
- `,` → read unquote / unquote-splicing
- `"` → read string (with interpolation)
- `#` → dispatch: `#\` char, `#(` vector, `#t`/`#f` booleans
- `{` → read hash table literal
- digit or sign-then-digit → read number
- otherwise → read symbol

This is the standard approach for Lisp readers. No tokenizer needed — characters dispatch directly to sub-parsers.

**Alternatives considered:**
- Tokenizer + parser: unnecessary overhead for s-expressions where a single character determines the form
- Table-driven (like CL's readtable): more flexible but premature — reader macros are a non-goal

### Decision 2: Assembler accesses globals via new CL primitives

The assembler needs to mutate the global instruction vector, instruction source vector, label table, and procedure name table. Rather than exposing these mutable CL objects directly, we add thin CL primitives:

- `%instruction-vector-length` — returns `(fill-pointer *global-instruction-vector*)`
- `%instruction-vector-push!` — appends a resolved instruction + source instruction
- `%label-table-set!` — sets a label→PC mapping in the global label table
- `%procedure-name-set!` — sets a PC→name mapping in the procedure name table
- `%resolve-operation` — calls CL's `resolve-operations` on one instruction

The `%` prefix signals these are low-level internal primitives not for general use.

**Alternatives considered:**
- Expose the raw CL vectors/hash-tables to ECE: would require growable vector support (`vector-push-extend` equivalent) which ECE vectors don't currently have, and would couple ECE code to CL internals
- Rewrite resolve-operations in ECE: would require ECE to have a mapping of operation names to CL function pointers, which is inherently a CL-level concern (the `#'function` references)

### Decision 3: Bootstrap sequence with explicit switchover

The bootstrap order is:
1. CL reader + CL compiler loads `prelude.scm`
2. CL reader + CL compiler loads `compiler.scm`
3. CL reader + CL compiler loads `reader.scm`
4. CL reader + CL compiler loads `assembler.scm`
5. Switchover: `ece-read` is rebound to call the ECE reader; `compile-and-go` uses ECE assembler

The CL `compile-file-ece` function handles the switchover: after loading assembler.scm, it sets a flag that causes subsequent reads and assemblies to go through ECE. The ECE REPL already calls `(read)` which routes to `ece-read`, so it automatically picks up the ECE reader.

**Alternatives considered:**
- Load reader.scm with the ECE reader (circular): impossible, the reader doesn't exist yet
- Immediate switchover per-file (switch reader after reader.scm loads): cleaner but the assembler.scm still needs the CL assembler during its own compilation

### Decision 4: Reader returns same data types as CL reader

The ECE reader produces exactly the same CL objects as the CL reader: CL symbols (upcased), CL cons cells, CL strings, CL characters, CL numbers. This ensures zero behavioral difference after switchover.

Symbols are interned via the existing `string->symbol` primitive. Numbers are parsed via `string->number`. Characters use `integer->char`.

### Decision 5: The ECE reader reads from ports, not raw CL streams

The reader takes an optional port argument (defaulting to `current-input-port`), consistent with the R7RS port model added in add-ports. This means `compile-file-ece` wraps the file stream in a port before calling the ECE reader in a loop.

## Risks / Trade-offs

- **Performance**: ECE reader will be slower than CL's native reader. Mitigated by: only matters at load time, and image-based bootstrap skips reading entirely. Not a concern for interactive REPL use.
- **String interpolation complexity**: The `$var` / `$(expr)` syntax requires the string reader to recursively call the full expression reader. Must ensure the recursive call uses the same reader (ECE reader calling ECE reader, not CL reader).
- **Bootstrap fragility**: If reader.scm or assembler.scm has a parse error, the CL reader reports it (since CL loads them). After switchover, errors in reloaded files would be reported by the ECE reader. Error messages may differ.
- **Operation resolution stays in CL**: `resolve-operations` maps symbolic operation names to CL function pointers (`#'lookup-variable-value`, etc.). This mapping is inherently CL-level and cannot move to ECE. The assembler calls it as a primitive.
