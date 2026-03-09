## Context

ECE compiles expressions to register machine instructions stored in a global instruction vector. Currently, `resolve-operations` converts `(op name)` forms to `(op-fn #<function>)` at assemble time for performance. These CL function pointers are not serializable, which prevents dumping the instruction vector to disk.

The global environment is already serializable — primitives are stored as `(primitive symbol-name)`. Compile-time macros store `(params body env)` which are pure s-expressions. The instruction vector is the only component that needs changes.

## Goals / Non-Goals

**Goals:**
- Store instructions in a form that can be serialized to disk and restored
- Provide `save-image!` and `load-image!` primitives accessible from ECE
- Round-trip all state: instruction vector, label table, environment, compile-time macros
- Re-resolve `op-fn` pointers on load so execution performance is preserved
- Comprehensive tests proving images survive save/load cycles

**Non-Goals:**
- Cross-platform image compatibility (SBCL-to-JSCL portability is a future concern)
- Incremental/delta image saves
- Image versioning or migration between ECE versions

## Decisions

### 1. Dual storage in instruction vector

**Decision:** Store both the original `(op name)` form and the resolved `(op-fn #<function>)` form in each instruction. Serialize the `op` form, resolve to `op-fn` on load.

**Approach:** `assemble-into-global` stores the original unresolved instruction in a parallel vector (`*global-instruction-source*`). The execution vector keeps `op-fn` for performance. On save, serialize the source vector. On load, run `resolve-operations` on each instruction to rebuild the execution vector.

**Alternative considered:** Remove `op-fn` entirely, always use `(op name)` with runtime dispatch via `get-operation`. Simpler but adds overhead to every operation call in the hot loop. Benchmarking may show this is negligible, but the dual approach preserves current performance with no risk.

### 2. Serialization format

**Decision:** Use CL's `write` with `*print-circle* t` and `*print-readably* t`, same as `save-continuation!`. Read back with `read` using `*ece-readtable*`.

**Rationale:** Already proven to work for continuations and environments. Handles circular structures. No external dependencies.

The image file contains a single list: `(instruction-source-vector label-alist environment macro-alist)`.
- Instruction source vector: serialized as a list of instructions (not a CL vector, to avoid reader issues)
- Label table: converted from hash-table to alist for serialization, restored to hash-table on load
- Environment: serialized as-is (already uses symbol names for primitives)
- Compile-time macros: converted from hash-table to alist for serialization

### 3. Load replaces global state

**Decision:** `load-image!` replaces the four global variables entirely. It does not merge with existing state.

**Rationale:** An image is a complete snapshot. Merging would create subtle bugs with duplicate bindings or stale instruction references. After loading, the system is in exactly the state it was when saved.

### 4. Primitives live in compiler.lisp

**Decision:** `save-image!` and `load-image!` are registered as primitives in `compiler.lisp` (like `try-eval` and `load`), but the underlying CL functions (`ece-save-image` and `ece-load-image`) are defined in `runtime.lisp` since they operate on runtime state.

**Rationale:** The functions manipulate runtime globals (instruction vector, label table, env), so the implementation belongs in runtime. But they're registered as ECE primitives in compiler.lisp alongside other compiler-dependent primitives.

## Risks / Trade-offs

- **Memory overhead of dual storage** → The source vector doubles instruction memory. For ECE's scale (thousands of instructions, not millions), this is negligible. If it matters later, we can drop `op-fn` and benchmark the `op` dispatch path.

- **Image file size** → Textual s-expression format may produce large files for big programs. Acceptable for now; binary format is a future optimization if needed.

- **Stale images** → If runtime.lisp changes (new operations, renamed primitives), old images may fail to load. No migration path is provided. This is acceptable — images are a cache, not an archive. Rebuild from source if needed.
