## Why

The `sandbox-and-tests-as-apps` change updated `ece-build` to produce a single `ECE_BOOTSTRAP_BUNDLE` string and updated `sandbox/ece-bootstrap.js` accordingly. But `sandbox.js` and `scripts/build-test-page.sh` still expect the old per-space `ECE_BOOTSTRAP["prelude"]` format. This causes two failures on GitHub Pages:
1. **Sandbox**: Bootstrap never loads, `eval-string` is undefined, `call_ece_proc` traps on null handle.
2. **Test page**: WASM instantiation fails because `runtime_error` import is missing from inline `io` object. Also has the same bootstrap format mismatch.

## What Changes

- **`sandbox/sandbox.js`**: Update `bootECE()` to load bootstrap via `ECE.loadEcecBundleText(atob(ECE_BOOTSTRAP_BUNDLE))`, matching the pattern already working in `templates/web/standalone.html`.
- **`scripts/build-test-page.sh`**: Add missing `runtime_error` and `trace_save_restore` to inline `io` imports. Switch bootstrap loading from per-space `ECE_BOOTSTRAP[name]` to single-bundle `ECE_BOOTSTRAP_BUNDLE` format.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

(none -- this is a bug fix, not a capability change)

## Impact

- `sandbox/sandbox.js` -- `bootECE()` rewritten to use bundle format
- `scripts/build-test-page.sh` -- inline JS updated for bundle format + missing WASM imports
- No changes to `ece-build`, `glue.js`, `runtime.wat`, or templates
