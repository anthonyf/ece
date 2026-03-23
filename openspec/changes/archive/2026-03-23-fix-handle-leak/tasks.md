## 1. Add handle recycling to sandbox

- [x] 1.1 Add `ECE.wasm.reset_handles()` at the top of `animationLoop` in `sandbox.js`
- [x] 1.2 Add `w.reset_handles()` before eval in `evalECE` in `sandbox.js`

## 2. Integration test

- [x] 2.1 Add yield/resume handle stability test: 100 cycles, verify handle counter stays bounded

## 3. Verification

- [x] 3.1 Run `make test-wasm` — 417 passed (387 ECE + 30 integration)
- [x] 3.2 Run `make sandbox` — builds successfully
