## Why

ECE currently depends on Common Lisp's reader and assembler for all parsing and code loading. Moving these to ECE makes the language self-hosting for all "interesting" parts — the reader, compiler, and assembler are all written in ECE, with CL reduced to a thin executor + primitives substrate. This enables image-based bootstrap (load a saved image, iterate on the language from within itself) and is a prerequisite for source location tracking in a future change.

## What Changes

- Add `reader.scm`: a full s-expression reader written in ECE, using the port and character I/O primitives added in add-ports
  - Numbers (integer, float, negative)
  - Strings with escape sequences (`\n`, `\t`, `\\`, `\"`)
  - String interpolation (`$var`, `$(expr)`, `$$`)
  - Symbols (upcased to match CL convention)
  - Characters (`#\a`, `#\space`, `#\newline`, `#\tab`)
  - Quote (`'x`), quasiquote (`` `x ``), unquote (`,x`), unquote-splicing (`,@x`)
  - Lists with dotted pair support
  - Vectors (`#(...)`)
  - Hash table literals (`{k v ...}`)
  - Line comments (`;`)
  - Boolean `#t` / `#f` → `t` / `()`
  - EOF sentinel
- Add `assembler.scm`: an assembler written in ECE that replaces `assemble-into-global`
  - Walk instruction list, distinguish labels from instructions
  - Append to global instruction vector, register labels in label table
  - Handle `procedure-name` pseudo-instructions
  - Resolve `(op name)` to function references at assembly time
- Wire the ECE reader into `ece-read`, `compile-file-ece` / `load`, and the REPL
- Wire the ECE assembler into `compile-and-go` and `mc-compile-and-go`

## Capabilities

### New Capabilities
- `ece-reader`: S-expression reader written in ECE, parsing all ECE syntax from ports
- `ece-assembler`: Instruction assembler written in ECE, replacing CL's `assemble-into-global`

### Modified Capabilities
- `repl`: REPL uses ECE reader instead of CL reader
- `load-file`: `load` uses ECE reader instead of CL reader
- `compile-and-go`: compilation pipeline uses ECE assembler instead of CL assembler

## Impact

- `src/reader.scm` — new file, loaded during bootstrap after compiler.scm
- `src/assembler.scm` — new file, loaded during bootstrap after reader.scm
- `src/runtime.lisp` — CL reader/assembler kept for cold bootstrap but no longer on hot path; new primitives exposed for vector/hash-table mutation needed by assembler
- `src/compiler.lisp` — `compile-and-go` and `compile-file-ece` updated to delegate to ECE assembler after switchover
- `src/compiler.scm` — `mc-compile-and-go` updated to use ECE assembler
- Bootstrap sequence: prelude → compiler → reader → assembler → switchover
