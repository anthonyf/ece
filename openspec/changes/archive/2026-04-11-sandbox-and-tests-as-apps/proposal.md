## Why

The sandbox and WASM test suite each have bespoke build scripts that duplicate the packaging logic now available in `ece-build`. The sandbox uses `scripts/build-sandbox.sh` to manually base64-encode WASM, inline glue.js, and embed bootstrap .ecec files — exactly what `ece-build --target web` already does. The WASM test suite concatenates .scm files into a single blob instead of using `compile-system` for multi-space bundles. Consolidating on `ece-build` eliminates duplication and proves the build system works for real projects.

## What Changes

- **Refactor sandbox build to use `ece-build`**: The `make sandbox` target calls `ece-build --target web` to generate `ece-runtime.js` and `ece-bootstrap.js`, then layers sandbox-specific files (`sandbox.js`, `index.html`, `ece-programs.js`) on top. Pre-compiled canned programs use `compile-system` to produce an `ece-compiled.js` bundle. `scripts/build-sandbox.sh` is removed.
- **Refactor WASM test build to use `compile-system`**: The `make test-wasm` target uses `compile-system` to compile test .scm files into a multi-space bundle instead of concatenating source files. `wasm/test.js` uses `loadEcecBundleText` to load the bundle.
- **Update Makefile**: Both `sandbox` and `test-wasm` targets rewritten to use `ece-build` / `compile-system`.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

(none — this is a build refactoring, not a capability change)

## Impact

- **`scripts/build-sandbox.sh`**: Removed (replaced by Makefile + ece-build).
- **`Makefile`**: `sandbox` and `test-wasm` targets rewritten.
- **`wasm/test.js`**: Updated to load multi-space bundles via `loadEcecBundleText`.
- **`sandbox/`**: Handwritten files (`sandbox.js`, `index.html`, `ece-programs.js`) unchanged. Generated files (`ece-runtime.js`, `ece-bootstrap.js`, `ece-compiled.js`) now produced by `ece-build`.
- **No user-facing behavioral changes**: Sandbox looks and works identically. WASM tests produce same results.
