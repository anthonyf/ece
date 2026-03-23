## Why

The WAT `.ecec` reader has a data correctness bug that causes complex prelude-compiled functions to behave differently from runtime-compiled identical code. Two confirmed symptoms:

1. **yield**: The `call/cc` winding wrapper's closure had `raw-k` as type 10 (i31 non-fixnum) instead of type 7 (continuation). The `ecec-op-id` off-by-one for `capture-continuation` was one cause — but after fixing it, other prelude functions still fail.
2. **serialize-value**: Crashes calling `cdr` on a non-pair deep in compiled code. All individual primitives work. Runtime-compiled identical serializer code works perfectly.

This blocks save/load (PR #39) and potentially affects other complex prelude functions that haven't been exercised yet.

## What Changes

- Build a systematic comparison tool: load the same `.ecec` file via the old binary loader AND the WAT reader, diff all instruction `$val` fields
- Identify the specific instruction pattern(s) where the WAT reader produces different values
- Fix the WAT reader to produce identical instruction output to the binary loader
- Add a regression test that catches val field differences

## Capabilities

### New Capabilities

- `wat-reader-comparison-test`: Automated test that compares WAT reader output against a known-good reference for all instruction val fields

### Modified Capabilities

## Impact

- `wasm/runtime.wat`: WAT reader bug fixes (in `$ecec-parse-instr`, `$ecec-build-operand-list`, `$ecec-read-*`, or `$ecec-check-special`)
- `wasm/test.js`: Comparison test
- Unblocks: save/load (PR #39), any other prelude function that's silently broken
