## Context

ECE errors currently report procedure name and PC offset but no source file or line number. The CL runtime provides backtraces with `(proc . pc)` pairs; the WASM runtime provides only an error message string. Both runtimes execute compiled code from `.ecec` files, which contain flat instruction lists with no source provenance.

The reader is written in ECE (`src/reader.scm`), compiles to `.ecec`, and runs on the register machine. The compiler (`src/compiler.scm`) expands macros at compile time and emits instruction sequences. Ports are simple wrappers around streams (CL) or buffers (WASM) with no line tracking.

## Goals / Non-Goals

**Goals:**
- Track line and column numbers in ports during character I/O
- Record source locations for every list expression during reading
- Propagate source locations through macro expansion via inherited location
- Emit per-space source maps in `.ecec` files
- Resolve PC to `file:line:col` in error messages and backtraces on both CL and WASM
- Sub-expression granularity (every list gets a location, not just top-level forms)

**Non-Goals:**
- Source locations on atoms (symbols, numbers, characters) — lists cover all meaningful expression boundaries
- Syntax objects or wrapped datum types (Racket/Chez style) — too invasive for ECE's architecture
- Interactive debugger or stepping — separate roadmap item
- Source location in REPL-entered expressions — no file to reference; PC is sufficient

## Decisions

### 1. Side-table hash keyed by cons cell identity

**Choice:** The reader populates a global hash table `*source-locations*` mapping each freshly-allocated list (by `eq?` identity) to `(file line col)`. The compiler checks this table when compiling each expression.

**Why not annotations/wrappers (Chez style)?** Wrappers require every downstream consumer (compiler, macro expander, all predicates like `pair?`, `car`, `cdr`) to unwrap. The reader is in ECE, so changing its return type would require coordinated changes across reader, compiler, and prelude — high risk, high effort.

**Why not compiler-only tracking (CHICKEN style)?** Compiler-only gives top-level-form granularity at best. With port line tracking already needed, the reader can cheaply record per-list positions, giving sub-expression granularity for minimal additional effort.

**Trade-off:** Atoms don't get source locations. An error on a bare symbol (e.g., unbound variable `x`) reports the location of the enclosing expression, not `x` itself. This is acceptable — you always know which expression contains `x` from the enclosing list's location.

### 2. Port line/column tracking in `read-char`

**Choice:** Add `line` (1-based) and `col` (0-based) fields to ports. `read-char` increments `col` on each character and resets to 0 / increments `line` on newline.

**CL implementation:** Extend port structure from `(input-port stream)` to `(input-port stream name line col)`. Wrap `ece-read-char` to update line/col.

**WASM implementation:** Add `$line (mut i32)` and `$col (mut i32)` fields to the `$port` struct. Update `$port-read-char` to track them.

**Why track in the port?** The reader calls `read-char` and `peek-char`. Tracking in the port means the reader doesn't need to count characters — it just queries `(port-line port)` and `(port-col port)` when it starts reading a list.

### 3. `*current-source-location*` parameter for macro propagation

**Choice:** The compiler maintains a `*current-source-location*` parameter. At the top of `mc-compile`, if the expression has a source location in the hash table, update the parameter. If not (macro-generated code), inherit the current value.

```
mc-compile(expr):
  loc = hash-ref(*source-locations*, expr, #f)
  if loc: *current-source-location* = loc
  emit source-map entry at current PC using *current-source-location*
  ... dispatch and compile as today ...
```

**Why this works for macros:** Macro expansion creates new cons cells for template structure but passes through original sub-expressions unchanged. The original sub-expressions retain their hash entries. The macro-generated wrapper code inherits the call site's location. This gives correct attribution:
- `(when (> x 0) (display "pos"))` at line 42
- Expands to `(if (> x 0) (begin (display "pos")))`
- `(if ...)` inherits line 42 from `(when ...)`
- `(> x 0)` keeps its own location (line 42, col 6)
- `(display "pos")` keeps its own location (line 42, col 17)

No changes to macros or the macro expander are needed.

### 4. Source map in `.ecec` header, per-space hash table at runtime

**Choice:** `compile-file` collects source-map entries during compilation and writes them as a new field in the ecec-header:

```scheme
(ecec-header
  (space prelude)
  (macros (cond let ...))
  (source-map "prelude.scm" (0 1 0) (14 5 0) (28 5 10) ...))
```

Each `(pc line col)` triple maps an absolute PC to a source position. The filename appears once.

At load time, the loader reads the source-map and builds a hash table keyed by PC. The hash table is registered in a global `*source-maps*` table keyed by space name:

```scheme
*source-maps*: space-name → { pc → (file line col) }
```

**Why hash table over sorted array + binary search?** ECE already has hash tables on both runtimes. O(1) lookup, no need for sorted-order invariants, simpler code.

**Why per-space?** PCs are local to each compilation space. The runtime already tracks `*executing-space-id*`. The lookup is: `(hash-ref (hash-ref *source-maps* space) pc)`.

### 5. Error handler resolves PC to location

**Choice:** The error formatting code in both runtimes looks up the current PC (and backtrace PCs) in the source-map hash table.

**CL runtime:** `ece-runtime-error` report function and `format-ece-backtrace` resolve each `(space . pc)` pair to `file:line:col`.

**WASM runtime:** The error-sentinel path and `$signal-error-str` look up the current PC before throwing.

**Output format:**
```
Error: Unbound variable: foo
  in procedure: process-input (game.scm:34:10)
  backtrace:
    [0] process-input at game.scm:34:10
    [1] eval at compiler.scm:719:0
    [2] repl-loop at prelude.scm:803:0
```

### 6. Backward compatibility with old `.ecec` files

**Choice:** The `source-map` field is optional in the ecec-header. Old `.ecec` files without it continue to work — the loader simply doesn't register a source map for that space, and error messages fall back to showing `pc=N` as today.

**Migration:** `make bootstrap` recompiles all `.scm` → `.ecec` with source maps. No two-pass migration needed since source maps are purely additive.

## Risks / Trade-offs

**[Reader hash table memory]** Every list expression gets an entry in `*source-locations*`. For a large file, this could be thousands of entries. → Mitigation: The hash table is only needed during compilation. After `compile-file` writes the source map to `.ecec`, the table can be cleared. At runtime, only the compact per-space PC→location hash tables persist.

**[Port field additions require bootstrap awareness]** Adding fields to ports in `prelude.scm` means old `.ecec` boot files use the old port structure. → Mitigation: CL primitives (`ece-read-char`, etc.) check for the presence of line/col fields and gracefully handle old-format ports. After one bootstrap cycle, all ports use the new format.

**[Source map size in `.ecec` files]** Each entry is `(pc line col)` — roughly 10-15 characters. At sub-expression granularity, prelude might have ~3000-5000 entries = ~40-75KB. → Mitigation: This is <0.2% of prelude.ecec's size. Acceptable overhead for the diagnostic value.

**[`eq?`-keyed hash fragility]** If macro expansion copies a sub-expression (e.g., via `list` instead of passing through), the copy won't be in the hash. → Mitigation: The `*current-source-location*` inheritance handles this — the copy inherits the enclosing expression's location. Incorrect by a few lines at worst, never missing entirely.
