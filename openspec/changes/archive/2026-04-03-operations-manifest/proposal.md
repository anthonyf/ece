## Why

ECE's register machine operations — the ~27 internal functions like `lookup-variable-value`, `extend-environment`, `make-compiled-procedure` — are hardcoded separately in each host runtime. CL has `get-operation` with its own ordering, WASM has `$ecec-op-id` with a different ordering (0-22). There is no shared manifest. The compile-to-host codegen needs to reference operations by stable ID, and any new host runtime needs a clear spec of what operations to implement. This is the same gap that `primitives.def` closed for primitives.

## What Changes

- **New `operations.def` file**: Manifest of all register machine operations with stable numeric IDs, name, arity, and description. Same format as `primitives.def`.
- **CL runtime update**: `get-operation` in `runtime.lisp` driven by the manifest instead of a hardcoded `ecase`. Operation dispatch uses a lookup table indexed by ID (same pattern as primitive dispatch).
- **WASM runtime update**: Operation dispatch in `runtime.wat` aligned to the canonical IDs from the manifest. The current WASM op-id numbering (0-22) may shift to match the manifest.
- **Manifest parsing**: Extend existing manifest infrastructure (or add parallel infrastructure) to parse `operations.def` and build dispatch tables at boot time.

## Capabilities

### New Capabilities
- `operations-manifest`: Canonical registry of register machine operations with stable numeric IDs, parsed at boot to build dispatch tables. Covers the manifest file format, ID assignment, and the contract each host must fulfill.

### Modified Capabilities
- `instruction-executor`: The executor's operation dispatch changes from hardcoded name→function mapping to manifest-driven ID→function lookup.

## Impact

- **`operations.def`** (new): The manifest file, ~27 entries.
- **`src/runtime.lisp`**: `get-operation` replaced with manifest-driven dispatch table. `resolve-operations` updated to use operation IDs.
- **`wasm/runtime.wat`**: Operation ID constants aligned to manifest. `$ecec-op-id` mapping updated.
- **`wasm/glue.js`**: May need updates if the .ecec loader's op-name→ID mapping changes.
- **Bootstrap**: Two-pass `make bootstrap` needed since .ecec files contain compiled operation references. First pass uses old IDs, second pass uses new.
- **Codegen (future)**: This change establishes the stable ID surface that the codegen will emit references to.
