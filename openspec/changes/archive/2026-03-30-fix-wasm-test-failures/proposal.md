## Why

The WASM ECE test suite has two bugs that cause test failures and a crash, preventing the suite from completing. CI uses `continue-on-error: true` to work around this. Fixing these enables the WASM test step to run cleanly.

## What Changes

- Fix `$fold-sub` in `runtime.wat`: the first operand's type is not checked when deciding whether to return fixnum or float. `(- 3.5 3)` returns 0 instead of 0.5 because the result is truncated to i32 even though the first arg is a float. This breaks `(round 3.5)` → returns 3 instead of 4.
- Fix `$wrap-f64` in `runtime.wat`: `i32.trunc_f64_s` traps when the f64 exceeds ±2^31, even though the intent is to demote to fixnum only when in range. The range check must happen *before* the trunc. This causes "float unrepresentable in integer range" crash during TCO tests.
- Remove `continue-on-error: true` from CI WASM test step once tests pass.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `wasm-runtime-errors`: Fix arithmetic result type and trunc trap in WASM fold/wrap functions

## Impact

- **wasm/runtime.wat**: Fix `$fold-sub` (check first-arg type) and `$wrap-f64` (guard trunc with range check)
- **.github/workflows/test.yml**: Remove `continue-on-error: true` from WASM test step
