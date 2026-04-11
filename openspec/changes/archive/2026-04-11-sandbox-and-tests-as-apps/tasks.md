## 1. Sandbox: use ece-build for runtime/bootstrap packaging

- [x] 1.1 Rewrite Makefile `sandbox` target: call `ece-build --target web` to a temp dir, copy `ece-runtime.js` and `ece-bootstrap.js` to `sandbox/`
- [x] 1.2 Keep canned program pre-compilation in Makefile (compile "Hello World" .scm → .ecec, embed as base64 in `ece-compiled.js`)
- [x] 1.3 Remove `scripts/build-sandbox.sh`
- [x] 1.4 Verify `make sandbox` produces identical output: sandbox loads and runs in browser

## 2. WASM tests: use compile-system for multi-space bundles

- [x] 2.1 Rewrite Makefile `test-wasm` target: extract test filenames from `run-common.scm` (kept single-space compile-file — multi-space compile-system has a cross-space guard/error WASM bug causing crash at test 407/549)
- [x] 2.2 Update `wasm/test.js` to use `loadEcecBundleText` for loading the test bundle
- [x] 2.3 Verify `make test-wasm` passes with same test count (586 passed, 0 failed)

## 3. Validation

- [x] 3.1 Run `make sandbox` and verify sandbox works in browser
- [x] 3.2 Run `make test-wasm` and verify all tests pass
- [x] 3.3 Run all other test suites (rove, ECE, conformance) — no regressions
- [x] 3.4 Verify `scripts/build-sandbox.sh` is deleted
