## Why

The WASM `.ecec` loader in `runtime.wat` hard-codes a 65,536-instruction capacity when creating compilation spaces. The bundled WASM test suite (`ece-wasm-tests.ecec`) compiles to ~71,758 instructions, exceeding this limit and causing an "array element access out of bounds" trap. This has kept `test-wasm` disabled in the `make test` target since the test suite grew past the capacity.

## What Changes

- Move the `create-space-internal` call in `load_ecec` from before Phase 1 (counting) to after Phase 1, using the actual instruction count (`$pc`) as the capacity instead of the hard-coded 65536.
- Re-enable `test-wasm` in the Makefile `test` target and remove the TODO comment about the bug.

## Capabilities

### New Capabilities
- `dynamic-ecec-capacity`: The `.ecec` loader dynamically sizes compilation spaces based on the actual instruction count from the two-pass scan, removing the fixed 65,536 limit.

### Modified Capabilities

## Impact

- `wasm/runtime.wat`: `load_ecec` function — reorder space creation to after the Phase 1 counting loop
- `Makefile`: Re-enable `test-wasm` in the `test` phony target
