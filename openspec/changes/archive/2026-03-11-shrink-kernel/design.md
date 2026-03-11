## Context

The CL runtime has ~257 lines of compaction code that walks ECE data structures (env, macros, procedure-name table, instruction source vector). ECE already has primitives for manipulating the instruction vector and label table (`%instruction-vector-length`, `%label-table-ref`, etc.). The compaction algorithm can be expressed entirely in ECE with a few new accessor primitives.

## Goals / Non-Goals

**Goals:**
- Move compaction logic from CL to ECE, reducing runtime.lisp by ~257 lines
- Add minimal new CL primitives for ECE-side state access
- Remove `print-text` and `lines` from the prelude
- All existing tests pass unchanged

**Non-Goals:**
- Changing the compaction algorithm itself (same block-boundary + transitive retention approach)
- Moving image serialization to ECE (CL still handles `write`/`read` with `*print-circle*`)

## Decisions

### Decision 1: New CL primitives for state access

The ECE compaction code needs read access to global state tables that are currently CL-internal. Add these thin accessor primitives:

- `%instruction-source-ref pc` — return the source instruction at PC
- `%instruction-source-length` — return length of the source vector (alias for `%instruction-vector-length`)
- `%procedure-name-entries` — return alist of `(pc . name)` from `*procedure-name-table*`
- `%label-table-entries` — return alist of `(label . pc)` from `*global-label-table*`
- `%macro-table-entries` — return alist of `(name . proc)` from `*compile-time-macros*`

These are all one-line CL wrappers. They expose read-only access to existing global tables.

### Decision 2: `save-image!` calls ECE compaction, passes result to CL serializer

The flow becomes:

```
save-image! (ECE)
  └─ compact-for-save (ECE) → returns compacted state
  └─ %write-image filename state (CL) → serializes with *print-circle*
```

A new CL primitive `%write-image` takes a filename and a pre-built data list (the same 7-element list format currently used) and writes it. This is ~15 lines of CL — the file-opening, `*print-circle*`, `handler-bind` for unreadable objects.

`save-image!` itself becomes an ECE function that calls `compact-for-save`, assembles the data list, and passes it to `%write-image`.

### Decision 3: ECE compaction lives in `src/compaction.scm`

A new file loaded during cold boot (after the prelude, compiler, reader, assembler). It defines:
- `compact-for-save` — the main orchestrator
- All helper functions (collect PCs, mark blocks, compact vector, remap, deep-copy)

This file gets compiled into the image like the other ECE source files.

### Decision 4: Deep-copy-and-remap uses ECE's existing data introspection

ECE can test `(eq? (car val) 'compiled-procedure)` and `(eq? (car val) 'continuation)` to identify values that need PC remapping. Environment walking uses `car`/`cdr` to traverse frames. The visited set for cycle detection uses an ECE hash table.

### Decision 5: Remove `print-text`, `lines`, and `fmt` from prelude

Delete all three definitions. `write-to-string` stays (compiler depends on it, and string interpolation now uses it directly). Remove the symbol exports from the CL package declaration.

### Decision 6: Reader expands string interpolation to `string-append` + `write-to-string`

Currently `~"Hello ~{name}"` expands to `(fmt "Hello " name)`. Change the reader to expand to `(string-append "Hello " (write-to-string name))` instead.

The reader already distinguishes literal string segments from interpolated expressions. For each interpolated expression, wrap it in `(write-to-string expr)`. Literal segments pass through as-is. Wrap everything in `(string-append ...)`.

Edge cases:
- No interpolation (single literal): return the string directly (already handled)
- Single interpolated expr, no literals: `(write-to-string expr)`
- Mixed: `(string-append lit1 (write-to-string expr1) lit2 (write-to-string expr2))`

## Risks / Trade-offs

**[Risk] Bootstrap ordering** — `compaction.scm` must be loaded after the assembler (since it defines functions that get compiled). It must also be loaded before the image is saved. Mitigation: add it to the cold-boot load sequence in the right position.

**[Risk] Performance** — ECE compaction will be slower than CL compaction (interpreted overhead). Mitigation: compaction only runs at save-image time, not at runtime. Even 10x slower is fine — milliseconds vs. tens of milliseconds.

**[Trade-off] More primitives** — We add ~6 new CL primitives. But each is a one-line accessor, and they're useful beyond compaction (debugging, introspection). Net CL reduction is still ~240 lines.
