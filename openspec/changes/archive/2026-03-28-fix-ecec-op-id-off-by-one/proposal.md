## Why

The WASM ecec text loader has an off-by-one bug in `$ecec-op-id` (`runtime.wat:5092`). It scans asm-sym-ids slots 17–38, missing slot 39 where `do-continuation-winds` (op 22) lives. This causes every `(perform (op do-continuation-winds) ...)` instruction to get `c=-1` instead of `c=22`, failing space validation for all 5 bootstrap spaces. This is the root cause of all 5 current `make test-wasm` failures.

## What Changes

- Fix the scan range in `$ecec-op-id` to include slot 39 (op 22, `do-continuation-winds`)
- Update the comment to reflect the correct range (slots 17–39, not 17–38)
- Rebuild `runtime.wasm`

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

_None — this is a bug fix, not a behavioral change. The executor already dispatches op 22 correctly; only the ecec text loader's op-id resolution is broken._

## Impact

- **wasm/runtime.wat**: One-line fix in `$ecec-op-id` scan range, comment update
- **wasm/runtime.wasm**: Rebuilt binary
- All 5 space validation test failures resolved (`make test-wasm` goes from 5 failures to 0)
- No behavioral change to the executor or compiled output
