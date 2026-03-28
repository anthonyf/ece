## Why

WASM test suite is 326/329 — 3 remaining failures from missing primitive edge cases. Fixing these achieves full parity with the CL host on the common test suite.

## What Changes

- `hash-ref` (prim 143): handle optional default argument when key not found
- `string->number`: fix edge case causing wrong result
- `make-parameter` (prim 88): apply converter function to initial value when provided

## Capabilities

### Modified Capabilities
- `wasm-primitives`: Fix 3 primitive edge cases in WAT

## Impact

- **wasm/runtime.wat**: ~15 lines changed across 3 primitives
- **bootstrap/*.ececb**: rebuilt (no prelude changes, just runtime fix)
