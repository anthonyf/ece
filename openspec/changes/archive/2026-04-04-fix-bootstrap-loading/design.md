## Context

`ece-build --target web --standalone` generates `ECE_BOOTSTRAP_BUNDLE` -- a single base64 string of the entire `bootstrap.ecec` bundle. The correct loading pattern exists in `templates/web/standalone.html`:

```js
const bootText = atob(ECE_BOOTSTRAP_BUNDLE);
ECE.loadEcecBundleText(bootText);
```

Two consumers were not updated to this format:
1. `sandbox/sandbox.js` `bootECE()` -- still iterates per-space `ECE_BOOTSTRAP[name]` entries
2. `scripts/build-test-page.sh` -- inline JS does the same, plus is missing `runtime_error` and `trace_save_restore` in the `io` imports

## Goals / Non-Goals

**Goals:**
- Fix sandbox and test page to load bootstrap using the bundle format
- Add missing WASM import functions to the test page
- Both pages work on GitHub Pages

**Non-Goals:**
- Changing `ece-build` output format
- Changing `glue.js` or `runtime.wat`
- Changing the standalone template (already correct)

## Decisions

### 1. sandbox.js: Use loadEcecBundleText with ECE.globalEnvHandle

Replace the per-space loop in `bootECE()` with:
```js
ECE.globalEnvHandle = Sandbox.envHandle;
const bootText = atob(ECE_BOOTSTRAP_BUNDLE);
ECE.loadEcecBundleText(bootText);
ECE.wasm.mark_handles();
```

This matches the standalone template exactly. `loadEcecBundleText` internally iterates sections, loads each space, and executes them in order. Setting `ECE.globalEnvHandle` is required because `loadEcecBundleText` uses it for `w.run()` calls.

### 2. build-test-page.sh: Use ECE.io directly instead of inline object

The test page currently constructs its own inline `io` object with only 4 of 6 required functions. Instead, override only `display_string`, `display_number`, and `newline` on `ECE.io` (for test output capture), then pass `ECE.io` as the import. This way `runtime_error` and `trace_save_restore` from `glue.js` are automatically included, and future import additions won't break the test page.

### 3. build-test-page.sh: Use loadEcecBundleText for bootstrap

Replace the per-space `.ececb` binary loading loop with the same bundle pattern:
```js
ECE.globalEnvHandle = envH;
const bootText = atob(ECE_BOOTSTRAP_BUNDLE);
ECE.loadEcecBundleText(bootText);
ECE.wasm.mark_handles();
```

This eliminates the `parseBinary`/`loadParsed` code path for bootstrap loading. The test `.ececb` loading can stay as-is since it uses a different code path.

Wait -- the test page currently loads test data as `.ececb` binary via `parseBinary`. But `ece-runtime.js` (from glue.js) doesn't export `parseBinary` or `loadParsed`. These must come from the old per-space bootstrap code. Need to check if the test page still compiles tests to `.ececb` or `.ecec`.

Looking at `build-test-page.sh` lines 33-37: it compiles tests to `.ecec` then converts to `.ececb` via `convert-ecec-to-ececb`. The test runner then uses `parseBinary` and `loadParsed`. These functions exist in `ece-runtime.js` (the sandbox build includes them from glue.js).

For the test data, we can either:
- Keep `.ececb` binary format and `parseBinary`/`loadParsed` (they work fine for single-space data)
- Switch to `.ecec` text format and `loadEcecText` (simpler, no binary conversion needed)

Decision: Switch test data to `.ecec` text format. This eliminates the `convert-ecec-to-ececb` step and simplifies the build. The `.ecec` text file is base64-encoded either way, so size difference is minimal.

## Risks / Trade-offs

- **Test page base64 size**: `.ecec` text is slightly larger than `.ececb` binary when base64-encoded. Negligible for a test page.
- **parseBinary/loadParsed unused**: After this change, these functions are only used by the Node.js test runner (`wasm/test.js`). They remain in `glue.js` / `ece-runtime.js` but are no longer needed for the browser test page.
