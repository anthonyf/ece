## Why

The game loop demos (bouncing ball, sierpinski, analog clock) are broken after the drop-ececb change. When `call_ece_proc` resumes the yield continuation, it crashes with `ref.cast failed` because the `continuation?` type test fails on the raw continuation inside the `call/cc` winding wrapper's closure. The root cause is that making `$instr.$c` and `$instr.$val` mutable (needed for the WAT reader's label resolution pass) changes how V8/binaryen handles WasmGC nominal type dispatch — the `$continuation` struct is no longer recognized by `ref.test` during cross-executor resume from JS.

## What Changes

- Make `$instr.$c` and `$instr.$val` fields immutable again by rewriting the WAT reader's label resolution to a true two-phase approach: first read ALL units and collect ALL labels, then create all instructions with labels already resolved at construction time
- Remove the post-creation `$ecec-resolve-labels` pass that mutates instruction fields
- Remove the `$cont-tag` field added to `$continuation` (no longer needed once `$instr` fields are immutable)

## Capabilities

### New Capabilities

- `immutable-instr-resolution`: WAT reader resolves labels at instruction creation time without requiring mutable $instr fields

### Modified Capabilities

## Impact

- `wasm/runtime.wat`: `$instr` type definition (revert to immutable), `load_ecec` function (two-phase), `$ecec-parse-instr` (takes labels param), `$ecec-build-operand-list` (takes labels param), remove `$ecec-resolve-labels` and `$ecec-resolve-operand-labels`
- `wasm/runtime.wat`: `$continuation` type (remove `$cont-tag` field), `struct.new $continuation` (remove tag arg)
- Sandbox game loop demos become functional again
- No API changes — `load_ecec` export signature unchanged
