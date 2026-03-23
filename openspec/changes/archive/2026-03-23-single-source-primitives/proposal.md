## Why

The primitive ID→name mapping is maintained in 3 places: `primitives.def` (canonical, 169 entries), `glue.js` `buildGlobalEnv` (62 hand-written entries), and `runtime.lisp` (116 wrapper mappings). Adding or renumbering a primitive requires editing all three. The off-by-one in `$ecec-op-id` that broke yield was this class of manual sync bug. Making `primitives.def` the single source of truth eliminates this.

## What Changes

- Add a build step that parses `primitives.def` and generates a JSON file (`wasm/primitives.json`) with the ID→name table
- Replace the hand-written `prims` array in `glue.js` `buildGlobalEnv` with a require of the generated JSON
- Add a Makefile target to regenerate `primitives.json` when `primitives.def` changes
- Add a test that verifies `primitives.json` is up to date with `primitives.def`

## Capabilities

### New Capabilities

- `generated-primitive-table`: Primitive ID→name table generated from primitives.def, not hand-maintained

### Modified Capabilities

## Impact

- `scripts/gen-primitives.sh` (or `.js`): New script that parses primitives.def → JSON
- `wasm/primitives.json`: Generated file (checked in for zero-dep builds)
- `wasm/glue.js`: `buildGlobalEnv` reads from JSON instead of inline array
- `Makefile`: New target for regeneration
- `wasm/test.js`: Staleness check test
- CL `runtime.lisp` is out of scope (separate change if desired)
