## Context

ECE's register machine compiler emits `(op name)` references in instructions. Each host runtime resolves these names to native functions:
- **CL**: `get-operation` — a 26-arm `ecase` mapping names to CL functions
- **WASM**: `$ecec-op-id` — symbol scan mapping names to hardcoded integers 0-22

The two runtimes have diverged: CL has 26 operations, WASM has 23. CL includes `lookup-global-variable`, `parameter-ref`, `parameter-set!`, `parameter-raw-set!` which WASM lacks. WASM includes `cdr` which CL's `get-operation` lacks. The numbering is completely different between the two.

For the compile-to-host codegen (written in ECE), operations need stable numeric IDs that both hosts agree on — identical to how `primitives.def` works for primitives.

## Goals / Non-Goals

**Goals:**
- Create `operations.def` with stable numeric IDs for all register machine operations
- Unify the CL and WASM operation sets (superset of both)
- Update CL's `get-operation` to use manifest-driven dispatch
- Update WASM's operation dispatch to use the canonical IDs
- Maintain the pre-resolution optimization (`resolve-operations` converting `(op name)` → `(op-fn #'func)` at assembly time in CL)

**Non-Goals:**
- Changing the compiler's output — it still emits `(op name)` in instructions
- Writing the codegen tool — this just establishes the ID surface it will use
- Adding new operations — this is a formalization of what already exists
- Changing the .ecec format — .ecec files still contain symbolic operation names; resolution happens at assembly/load time

## Decisions

### 1. Separate file: `operations.def`

**Choice:** A new file `operations.def` at the project root, alongside `primitives.def`.

**Why:** Operations and primitives serve different purposes (compiler-internal vs user-callable), have different dispatch paths, and different platform semantics (all operations are required on every host; primitives have platform tags). Keeping them separate avoids muddying `primitives.def` with filtering logic.

### 2. Canonical ID assignment

**Choice:** Assign IDs that match neither the current CL ordering nor the current WASM ordering. Use a logical grouping:

- 0-6: Environment operations (lookup, set, define, extend, lexical-ref/set)
- 7-9: Compiled procedure operations (make, entry, env)
- 10-12: Type predicates (primitive?, continuation?, parameter?)
- 13-16: Primitive/parameter dispatch (apply-primitive, apply-parameter, parameter-ref/set/raw-set)
- 17-18: Continuation operations (capture, do-winds)
- 19-21: Continuation accessors (stack, conts, continuation-winds)
- 22: Boolean test (false?)
- 23-26: Data constructors/accessors (list, cons, car, cdr)

**Why:** Both runtimes need to change regardless (they disagree now), so starting fresh with a logical ordering is cleaner than privileging one runtime's existing numbering.

### 3. CL dispatch: vector table indexed by ID

**Choice:** Replace the `ecase` in `get-operation` with a vector lookup: `(aref *operation-dispatch-table* id)`. The table is populated at load time by parsing `operations.def` and mapping names to CL functions via a name→function association (similar to `*primitive-dispatch-table*`).

`resolve-operations` continues to pre-resolve `(op name)` → `(op-fn #'func)` at assembly time. The manifest is only consulted during table initialization, not at runtime.

**Why:** Matches the existing pattern for primitives. Vector lookup by ID is O(1). The pre-resolution optimization means the manifest lookup happens once per instruction at assembly time, not per-execution.

### 4. WASM dispatch: update constants inline

**Choice:** Update the hardcoded integer constants in `runtime.wat` to match the canonical IDs. The `$ecec-op-id` function's symbol-scan slot assignments change to match. The `$exec-machine-op` dispatch `if/else` chain uses the new IDs.

**Why:** WASM doesn't have a manifest parser — the IDs are baked into the WAT source. This is the same approach WASM already uses for primitive IDs from `primitives.def`.

### 5. Operations missing from one runtime

**Choice:** Add the missing operations to each runtime:
- **WASM** gets: `lookup-global-variable`, `parameter-ref`, `parameter-set!`, `parameter-raw-set!`
- **CL** gets: `cdr` (trivially maps to CL's `cdr`)

Operations that exist in the manifest but aren't yet used by compiled code on a given platform will still have dispatch entries — the table slot exists but may never be called until the compiler starts emitting those ops for that platform.

**Why:** The manifest is the contract. Every host must implement every operation. Missing entries would cause runtime crashes if the compiler ever emits them.

### 6. Two-pass bootstrap

**Choice:** Standard two-pass `make bootstrap`:
1. Boot from existing .ecec files (old operation name resolution)
2. Recompile all .scm → .ecec with updated assembler
3. Boot from new .ecec files (new operation name resolution)

**Why:** .ecec files contain symbolic operation names, not numeric IDs. The assembler resolves names to IDs at load time. After updating the assembler's resolution mapping, new .ecec files will resolve to the new IDs. The two-pass approach is the standard pattern for bootstrap changes.

## Risks / Trade-offs

**[WASM op-id renumbering]** All WASM operation IDs change. Any .ecec files assembled with old IDs will dispatch incorrectly on the WASM runtime. → Mitigation: two-pass bootstrap regenerates all .ecec files. The WASM .ecec loader resolves symbolic names at load time, so pre-assembled binary .ececb files need regeneration too.

**[Missing operation implementations in WASM]** `parameter-ref`, `parameter-set!`, `parameter-raw-set!`, and `lookup-global-variable` need WASM implementations. → Mitigation: `lookup-global-variable` is a thin wrapper around `lookup-variable-value` with the global env. The parameter operations are small. These are straightforward to implement.

**[Manifest divergence risk]** If someone adds an operation to one runtime without updating `operations.def`, the manifests drift apart again. → Mitigation: document the rule clearly. Future CI could validate manifest consistency.
