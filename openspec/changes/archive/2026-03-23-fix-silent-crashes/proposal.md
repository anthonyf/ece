## Why

The WASM runtime has three places where missing bounds checks or error handling cause confusing crashes instead of clear error messages. These were identified during an architecture review. All three produce "Out of bounds array.set" or "ref.cast failed" errors with no indication of the actual problem (too many symbols, undefined variable, or too many compilation spaces).

## What Changes

- **Symbol table overflow**: Add bounds check and array doubling growth in `$intern` when `sym-count >= sym-capacity` (currently 65536 hard-coded arrays with no check)
- **Undefined variable error**: Add a `runtime_error` JS import. When `lookup-variable-value` fails to find a variable, call it with the variable name instead of silently returning null
- **Space array overflow**: Add bounds check and array doubling growth in `$register-space` when `space-id >= array length`

## Capabilities

### New Capabilities

- `wasm-runtime-errors`: WASM runtime reports errors via JS import instead of silent null returns or array overflows

### Modified Capabilities

## Impact

- `wasm/runtime.wat`: Add `runtime_error` import, add bounds checks in `$intern` and `$register-space`, add error call in `lookup-variable-value`
- `wasm/glue.js`: Add `runtime_error` import handler (throws JS exception with the error message)
- `wasm/test.js`: Add import handler
- `sandbox/sandbox.js`: Add import handler
