## Why

`ece-build --target web` base64-encodes all binary data (WASM, bootstrap .ecec files, app .ecec) into JS files so apps work from `file://`. This adds 33% size overhead and prevents streaming WASM instantiation. For server-hosted deployment (GitHub Pages, any HTTP server), raw files loaded via `fetch()` are smaller, faster, and standard. Additionally, the bootstrap is 6 separate .ecec files loaded individually — `compile-system` can bundle these into a single file, simplifying loading for both build modes.

## What Changes

- **Single-file bootstrap bundle**: `make bootstrap` uses `compile-system` to produce one `bootstrap/bootstrap.ecec` from the 6 source .scm files. All consumers (CL runtime, WASM glue, ece-build) load the single bundle instead of iterating over individual files.
- **Server mode (new default)**: `ece-build --target web` produces raw files for HTTP serving: `runtime.wasm`, `bootstrap.ecec`, `app.ecec`, `ece-runtime.js` (glue only, no embedded WASM), and `index.html` (uses `fetch()` + `WebAssembly.instantiateStreaming()`).
- **Standalone mode**: `ece-build --target web --standalone` preserves the current base64-in-JS packaging for `file://` compatibility. `make sandbox` passes `--standalone`.
- **Server mode integration test**: New `make test-web-server` target builds a hello-world app in server mode, serves it with `python3 -m http.server`, and runs a Node.js client that fetches, boots, executes, and verifies output.

## Capabilities

### New Capabilities

- `web-server-mode`: Server-mode web deployment producing raw .wasm/.ecec files loaded via fetch()
- `bootstrap-bundle`: Single-file bootstrap produced by compile-system

### Modified Capabilities

- `app-packaging`: `--target web` default changes from standalone to server mode; new `--standalone` flag preserves current behavior

## Impact

- **`make bootstrap`**: Produces single `bootstrap/bootstrap.ecec` instead of 6 individual files
- **`bin/ece-build`**: New `--standalone` flag; default web target produces raw files
- **`Makefile`**: `sandbox` target passes `--standalone`; new `test-web-server` target
- **`wasm/glue.js`**: Bootstrap loading simplified to one `loadEcecBundleText` call
- **`templates/web/index.html`**: New server-mode template using `fetch()`; current template becomes `templates/web/standalone.html`
- **CL runtime**: Bootstrap loading updated to load single bundle file
- **GitHub Pages** (`make site`): Can switch to server mode for cleaner deployment
- **README.md**: Update web app build instructions with both modes
