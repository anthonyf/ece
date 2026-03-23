## Context

`primitives.def` has 169 entries (134 core, 21 browser, 14 cl). The `glue.js` `buildGlobalEnv` function has a hand-written `prims` array of 62 `[id, name]` pairs. These must stay in sync manually. The CL `runtime.lisp` has its own mapping (116 entries) but that's a separate concern — it maps names to CL implementation functions, not just ID→name.

## Goals / Non-Goals

**Goals:**
- `primitives.def` is the single source for WASM primitive registration
- Adding a primitive to `primitives.def` is sufficient — no manual `glue.js` edit needed
- Staleness detected automatically during tests

**Non-Goals:**
- Changing `runtime.lisp` (CL runtime) — separate change if desired
- Changing `primitives.def` format
- Auto-generating WAT dispatch code (the WAT `$apply-primitive` switch is a different concern)

## Decisions

### 1. Generation script: simple shell + awk

A shell script `scripts/gen-primitives-json.sh` parses `primitives.def` and outputs `wasm/primitives.json`. No Node.js dependency for generation — just `awk`, which is available everywhere.

Format of generated JSON:
```json
[[0,"+"], [1,"-"], [2,"*"], ...]
```

Same format as the current inline array, so `glue.js` changes are minimal.

Filter: include only entries where platform is `core` or `browser` (exclude `cl`).

### 2. glue.js reads from JSON

Replace the inline `prims` array with:
```javascript
const prims = require("./primitives.json");
```

In the browser sandbox, the JSON is embedded in the build output (base64 or inline). The `build-sandbox.sh` script handles this.

### 3. Check into git

`wasm/primitives.json` is checked into git so that builds work without running the generation step. The Makefile regenerates it when `primitives.def` changes. A test verifies it's not stale.

### 4. Staleness test

An integration test in `wasm/test.js` reads `primitives.def` from disk (Node.js has `fs`), parses it, and compares against `primitives.json`. Fails if they differ. This catches forgotten regeneration.

## Risks / Trade-offs

- **Checked-in generated file**: Some prefer not checking in generated files. But it avoids requiring `awk` at build time and works for zero-dep `git clone && make test-wasm`.
- **Browser build**: `build-sandbox.sh` currently embeds JS files. The JSON just needs to be available to `require()` at build time, which it already is since glue.js is bundled.
