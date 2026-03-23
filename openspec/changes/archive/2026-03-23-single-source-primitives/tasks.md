## 1. Generation script

- [x] 1.1 Create `scripts/gen-primitives-json.sh`: parse primitives.def, output wasm/primitives.json (core + browser only)
- [x] 1.2 Generate initial `wasm/primitives.json` — 150 entries, matches all hand-written entries

## 2. Update glue.js

- [x] 2.1 Replace inline `prims` array in `buildGlobalEnv` with `require("./primitives.json")`
- [x] 2.2 Removed 60+ line hand-written array

## 3. Update build pipeline

- [x] 3.1 Add `primitives-json` Makefile target with dependency tracking
- [x] 3.2 Update `build-sandbox.sh` to inline primitives.json as `ECE_PRIMITIVES` global

## 4. Staleness test

- [x] 4.1 Add integration test: parse primitives.def, compare against primitives.json, fail if stale

## 5. Verification

- [x] 5.1 Run `make test-wasm` — 420 passed, 0 failed (387 ECE + 33 integration)
- [x] 5.2 Run `make sandbox` — builds and runs correctly
