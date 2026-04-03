## Why

The CL runtime maintains two hand-edited lists (`*primitive-procedures*` and `*wrapper-primitives*`) that must stay in sync with `primitives.def`. Adding a primitive to the manifest without adding the CL mapping causes silent failures — this class of bug caused the yield/resume off-by-one. The WASM side already reads from a generated `primitives.json`; the CL side should eliminate its manual lists too.

## What Changes

- **Remove `*primitive-procedures*` and `*wrapper-primitives*`**: Replace these ~145 hand-maintained entries with convention-based resolution: try `ece-<name>` then `<name>` as CL function names automatically.
- **Small override table for non-conventional mappings**: ~15 entries where the CL function name doesn't follow convention (e.g., `char->integer` → `char-code`, `set-car!` → `rplaca`, `vector-ref` → `aref`).
- **Boot-time validation**: Error (not warn) if a `core` or `cl` platform primitive has no resolvable CL function. Catches missing implementations immediately instead of at first call.
- **WASM side unchanged**: Already single-sourced via `primitives.json`.

## Capabilities

### New Capabilities
- `generated-primitive-table`: Convention-based resolution of CL primitive implementations from `primitives.def`, replacing hand-maintained mapping lists.

### Modified Capabilities
- `primitive-manifest`: Boot-time validation that all required primitives have CL implementations.

## Impact

- **`src/runtime.lisp`**: Remove `*primitive-procedures*` (~15 lines), `*wrapper-primitives*` (~130 lines), and `build-cl-function-map`. Replace with convention-based resolver and small override table. Update `init-primitive-dispatch-tables`.
- **Bootstrap**: Two-pass `make bootstrap` needed (standard for runtime.lisp changes).
- **No .ecec changes**: Primitives are resolved by ID at runtime, not by name in .ecec files.
- **No WASM changes**: Already single-sourced.
