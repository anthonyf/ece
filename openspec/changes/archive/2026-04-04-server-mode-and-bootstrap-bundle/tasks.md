## 1. Single-file bootstrap bundle

- [x] 1.1 Rewrite `make bootstrap` to use `compile-system`: compile all 7 .scm sources into one `bootstrap/bootstrap.ecec`
- [x] 1.2 Remove individual .ecec files from `bootstrap/` (clean up old files)
- [x] 1.3 Update CL `boot-from-compiled` to load single `bootstrap.ecec`, skipping `browser-lib` section
- [x] 1.4 Update `wasm/glue.js` bootstrap loading to use single bundle via `loadEcecBundleText`
- [x] 1.5 Update `wasm/test.js` bootstrap loading to use single bundle
- [x] 1.6 Verify `make test` passes (all suites: rove, ECE, conformance, WASM, golden)

## 2. Server mode for ece-build

- [x] 2.1 Add `--standalone` flag parsing to `bin/ece-build`
- [x] 2.2 Implement server-mode packaging: copy `runtime.wasm`, `bootstrap.ecec`, `app.ecec`, emit glue-only `ece-runtime.js`
- [x] 2.3 Create `templates/web/index.html` for server mode (fetch + instantiateStreaming)
- [x] 2.4 Rename current template to `templates/web/standalone.html`
- [x] 2.5 Update standalone packaging to use single `bootstrap.ecec` (base64-encode one file instead of 6)
- [x] 2.6 Update `make sandbox` to pass `--standalone` to `ece-build`

## 3. Server mode integration test

- [x] 3.1 Create `wasm/test-server-mode.js`: fetch from localhost, instantiate WASM, boot, run, verify output
- [x] 3.2 Add `make test-web-server` target: build hello-world in server mode, start python3 server, run test, cleanup
- [x] 3.3 Verify `make test-web-server` passes

## 4. Validation and documentation

- [x] 4.1 Run `make test` — all existing suites pass, no regressions
- [x] 4.2 Run `make sandbox` — sandbox builds and works in browser
- [x] 4.3 Run `make site` — GitHub Pages build works
- [x] 4.4 Update README.md with both build modes (`--standalone` and default server mode)
