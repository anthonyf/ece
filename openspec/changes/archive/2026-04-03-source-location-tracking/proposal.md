## Why

When an error occurs in ECE, the user sees a procedure name and a PC offset (e.g., `process-input at pc=42`) but no source file or line number. This makes debugging difficult — the first question on any error is "where?" and the current output doesn't answer it. The WASM runtime is worse: errors produce only a message string with no context at all. Adding source location tracking throughout the compilation pipeline would let both runtimes report `game.scm:34` instead of `pc=42`.

## What Changes

- **Add line/column tracking to ports**: Both CL and WASM port structures gain line and column fields, updated on each `read-char`.
- **Reader records source locations**: `read-list` records `(file line col)` in a side-table hash keyed by cons cell identity. Every list expression gets a source position.
- **Compiler emits source-map entries**: `mc-compile` checks the side table for each expression and collects `(pc line col)` triples. A `*current-source-location*` parameter ensures macro-expanded code inherits the call site's location.
- **`.ecec` header gains a `source-map` field**: `compile-file` writes `(source-map "file.scm" (pc line col) ...)` into the ecec-header. Loaders build a per-space hash table from it.
- **Error handler resolves PC to file:line:col**: Both CL and WASM error paths look up the current PC in the source-map hash table and include the location in error messages and backtraces.

## Capabilities

### New Capabilities
- `source-location-tracking`: Port line/column tracking, reader source annotation, compiler source-map emission, `.ecec` source-map storage, and runtime PC-to-location resolution for error messages and backtraces.

### Modified Capabilities

## Impact

- **`src/reader.scm`**: `read-list` records source positions in a global hash table.
- **`src/compiler.scm`**: `mc-compile` checks source locations, propagates through macro expansion via `*current-source-location*` parameter, collects source-map entries.
- **`src/compilation-unit.scm`**: `compile-file` writes source-map to `.ecec` header; `load-compiled` reads it and registers per-space hash table.
- **`src/prelude.scm`**: Port constructors gain line/col fields; `read-char` updates them.
- **`src/runtime.lisp`**: CL port structure gains line/col; error formatter resolves PC to source location; backtrace includes file:line.
- **`wasm/runtime.wat`**: `$port` struct gains `$line`/`$col` fields; `$port-read-char` updates them; `.ecec` loader reads source-map; error path resolves PC to location.
- **`bootstrap/*.ecec`**: All files gain `source-map` header field after rebootstrap.
- **No behavioral changes**: All existing code continues to work. Source locations are additive — they enhance error output without changing semantics.
