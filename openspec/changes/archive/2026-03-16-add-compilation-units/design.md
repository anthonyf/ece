## Context

ECE's compiler (`mc-compile`) already produces symbolic instruction sequences as `(needs modifies instructions)` tuples. The assembler (`assemble-into-global`) appends these to the global instruction vector and resolves operations. Execution starts from a PC offset via `execute-from-pc`. The current `load` function tightly couples all three steps in a per-form loop via `mc-compile-and-go`.

The compiler is fully self-hosted in ECE. Macro definitions (`define-macro`) are compiled and executed at compile time via `mc-compile-define-macro`, which calls `mc-compile-and-go` on the transformer lambda and stores it in the compile-time macro table.

## Goals / Non-Goals

**Goals:**
- Expose `compile-form` as the core primitive returning a first-class compiled unit
- Support serialization/deserialization of compiled units as s-expressions
- Implement `compile-file` / `load-compiled` for file-level compilation
- Everything implemented in ECE, no CL kernel changes
- Compiled units are inspectable (you can read the instruction list)

**Non-Goals:**
- Optimized binary format (s-expressions are fine for now)
- Automatic recompilation when source changes (no `compile-file-if-needed` yet)
- Separate compilation with cross-file linking (files still resolve symbols via global env at load time)
- Changing how the existing `load` works

## Decisions

### 1. Compiled unit representation: tagged list

A compiled unit is `(compiled-unit <instructions>)` where `<instructions>` is the flat instruction list (what `mc-instructions` returns from `mc-compile`).

**Why not include needs/modifies?** Those are only useful for the compiler's instruction sequence combinator. By the time you have a compiled unit, sequencing is done. The flat instruction list is what the assembler consumes.

**Why tagged list, not a record?** Simplicity. A tagged list is trivially serializable with `write` and `read`. Records would need custom serialization. We can upgrade later if needed.

### 2. Serialization format: s-expressions via write/read

A `.ecec` file is a sequence of s-expressions, each being a compiled unit. You can `cat` the file and read it. `write-compiled-unit` uses `write` to a port; `read-compiled-unit` uses `ece-scheme-read`.

**Alternative considered:** Binary format using the existing image serializer. Rejected because the goal is inspectability and simplicity, not performance. The image format is for whole-system snapshots, not individual files.

### 3. Macro handling in compile-file: execute at compile time

When `compile-file` encounters a `define-macro` form, it must execute it immediately (via `mc-compile-and-go`) so subsequent forms in the same file can use that macro. The compiled output for the macro definition is still included in the compiled file so it gets re-registered when loaded.

This matches CL's behavior: `compile-file` evaluates `(eval-when (:compile-toplevel) ...)` forms. ECE's version is simpler — only `define-macro` needs compile-time evaluation.

**Detection:** Check if the form is a `define-macro` using `mc-define-macro?` (already exists in the compiler).

### 4. compile-form wraps mc-compile, strips needs/modifies

```
compile-form: expr → compiled-unit
  1. Call (mc-compile expr 'val 'next)
  2. Extract instruction list via mc-instructions
  3. Wrap as (compiled-unit <instructions>)
```

### 5. execute assembles and runs

```
execute: compiled-unit → value
  1. Extract instructions from the compiled unit
  2. Call (assemble-into-global instructions)  → start-pc
  3. Call (execute-from-pc start-pc)           → result
```

This is the same path `mc-compile-and-go` takes after compilation — we're just splitting it at the seam.

### 6. File layout

```
src/compilation-unit.scm    — compiled-unit type, compile-form, execute,
                              write/read, compile-file, load-compiled
```

Single new file. Loaded after `compiler.scm` and `assembler.scm` in the boot sequence. Redefines `load` to also support `.ecec` files (checking extension).

## Risks / Trade-offs

**Gensym serialization** — Labels in instruction lists are gensyms. `write` will produce `#:G123`-style output. `read` must recreate these as unique symbols. Since label references are always file-local (a label is defined and jumped to within the same compiled unit), we can serialize gensyms as numbered symbols (`$L0`, `$L1`, ...) with a renaming pass during write, and they'll be unique within the unit. → Mitigation: `write-compiled-unit` renames gensyms to deterministic labels before serializing.

**Macro side effects at compile time** — `compile-file` executing macros at compile time means compilation is not pure. This is inherent to any Lisp with macros and is the standard approach. → Accepted trade-off.

**No dependency tracking** — `load-compiled` doesn't verify that the compiled file was built against the same macros/environment. If macros change, you need to recompile manually. → Acceptable for now; `compile-file-if-needed` is a future enhancement.
