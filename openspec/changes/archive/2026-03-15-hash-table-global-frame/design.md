## Context

The ECE environment is a list of frames. Each frame is either:
- **List-based**: `((var1 var2 ...) . (val1 val2 ...))` — used by the global env and the metacircular compiler
- **Vector-based**: `#(val1 val2 ...)` — used by the CL compiler for lexical addressing (O(1) access)

The global environment is a single list-based frame with ~309 bindings. Every `lookup-variable-value` call walks this frame linearly. Profiling shows this accounts for 51% of CPU time during the test suite.

Three CL functions access frames by name: `lookup-variable-value`, `set-variable-value!`, `define-variable!`. These already skip vector frames (no variable names). They need to dispatch on a third frame type: hash-table.

The binary image serializer/deserializer and ECE-side compaction code both walk environment frames and must handle the new frame type.

## Goals / Non-Goals

**Goals:**
- O(1) global variable lookup via hash-table-backed frame
- Transparent to ECE code — no changes to the Scheme language semantics
- Backward-compatible image loading (auto-detect old format gracefully)
- Compaction and image round-trip work correctly with hash-table frames

**Non-Goals:**
- Changing local environment frames (they stay as vectors/lists)
- Adding lexical addressing to the metacircular compiler (separate future change)
- Optimizing `extend-environment` for local frames

## Decisions

### Frame representation: tagged cons cell
Use `(:hash-frame . <hash-table>)` where the hash-table maps symbols to values directly (not to positions in a list).

**Why not a bare hash-table?** Frames appear inside `(cons frame rest-of-env)`. The existing code uses `(vectorp frame)` to detect vector frames and `(consp frame)` for list frames. A tagged cons is distinguishable from both: `(and (consp frame) (eq (car frame) :hash-frame))`.

**Why not a wrapper struct?** Cons cells are simpler, already handled by the serializer, and the tag check is a single `eq` comparison.

### Which frames get hash-table treatment
Only the global frame. Local frames created by `extend-environment` remain as vectors (from CL compiler) or lists (from mc-compiler). The global frame is the only one with hundreds of bindings.

**Why?** Local frames are small (typically 1-10 bindings). Hash-table overhead would exceed linear-scan cost for small frames. The 309-element global frame is the bottleneck.

### Initialization
`*global-env*` is initialized by building a hash-table from `*primitive-procedure-names*` and `*primitive-procedure-objects*`, wrapped as `(:hash-frame . ht)`. The `ece-load-image` deserializer reconstructs the hash-table frame from serialized data.

### Serialization strategy
Serialize hash-table frames as a list of `(key . value)` pairs in the binary data section, preceded by a new data type tag `+data-hash-frame+`. On deserialization, rebuild the CL hash-table from the pairs.

This is simple, handles forward references via the existing def/ref mechanism, and doesn't require changes to the stack-machine data format — just a new compound type tag.

### Compaction (compaction.scm)
The ECE-side compaction walks environments to collect entry PCs and deep-copy with remapped PCs. Currently it expects list-based frames `(pair? frame)` with `(car frame)` = variables and `(cdr frame)` = values.

For hash-table frames, add a CL primitive `%hash-frame?` and `%hash-frame-entries` that returns an alist of `(key . value)` pairs. The compaction code can walk entries the same way it walks values. For deep-copy, add `%make-hash-frame` and `%hash-frame-set!` primitives.

### Variable access function changes

```
lookup-variable-value(var, env):
  for frame in env:
    if vector? frame → skip (no names)
    if hash-frame? frame → gethash, return if found
    if list frame → existing linear scan
  error "Unbound variable"

set-variable-value!(var, val, env):
  same dispatch, setf gethash for hash frames

define-variable!(var, val, env):
  find first non-vector frame
  if hash-frame → setf gethash
  if list frame → existing push-or-update
```

## Risks / Trade-offs

- **[Risk] ECE-side code assumes frame structure** → Mitigated by providing CL-backed primitives (`%hash-frame?`, `%hash-frame-entries`, etc.) so ECE code never inspects the raw structure.
- **[Risk] Serialization ordering with circular refs** → Hash-table frame entries contain compiled procedures that reference the environment (circular). The existing def/ref + forward-reference mechanism handles this — the hash-table frame gets a def ID, and compiled procedures within it use refs back to it.
- **[Trade-off] Slightly more memory for the global frame** → CL hash-table vs two lists. Negligible for a single 309-entry frame (~50KB overhead max).
- **[Trade-off] New primitives added to CL kernel** → `%hash-frame?`, `%hash-frame-entries`, `%make-hash-frame`, `%hash-frame-set!`. Four small functions, necessary for compaction.scm to handle the new frame type without directly inspecting CL structures.
