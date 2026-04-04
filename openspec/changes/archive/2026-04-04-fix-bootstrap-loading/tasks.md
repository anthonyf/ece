## 1. Fix sandbox bootstrap loading

- [x] 1.1 Update `sandbox/sandbox.js` `bootECE()`: replace per-space `ECE_BOOTSTRAP[name]` loop with `ECE.globalEnvHandle = Sandbox.envHandle; ECE.loadEcecBundleText(atob(ECE_BOOTSTRAP_BUNDLE)); ECE.wasm.mark_handles();`
- [x] 1.2 Verify sandbox loads and runs Hello World in browser (`make sandbox && open sandbox/index.html`)

## 2. Fix test page WASM imports and bootstrap loading

- [x] 2.1 Update `scripts/build-test-page.sh`: replace inline `io` object with overrides on `ECE.io` (display_string, display_number, newline for test output capture), then pass `ECE.io` as import so `runtime_error` and `trace_save_restore` are included
- [x] 2.2 Update `scripts/build-test-page.sh`: replace per-space `ECE_BOOTSTRAP[name]` bootstrap loop with `ECE.loadEcecBundleText(atob(ECE_BOOTSTRAP_BUNDLE))` pattern
- [x] 2.3 Update `scripts/build-test-page.sh`: switch test data from `.ececb` binary to `.ecec` text format (remove `convert-ecec-to-ececb` step, use `loadEcecText` instead of `parseBinary`/`loadParsed`)
- [x] 2.4 Verify test page loads and runs all tests (`make site && open _site/tests/index.html`)

## 3. Automated sandbox smoke test

- [x] 3.1 Create `wasm/test-web-apps.js`: Node.js script that validates sandbox files, boots WASM, loads bootstrap via bundle, runs `eval-string` on hello world, loads pre-compiled program, verifies output (6 checks)
- [x] 3.2 Add `test-web-apps` Makefile target (depends on `sandbox`), add to `test:` target list
- [x] 3.3 Fold browser verification tasks (1.2, 2.4) into the automated test

## 4. Validation

- [x] 4.1 Run `make test-wasm` -- existing WASM tests still pass (586 passed, 0 failed)
- [x] 4.2 Run `make test` -- all test suites pass (116 rove + 558 ECE native, no regressions)
- [x] 4.3 Run `make test-web-apps` -- new smoke test passes (6 passed, 0 failed)
