## Why

WASM's `modulo` uses `i32.rem_s` (truncation semantics) instead of R7RS-correct floor semantics. `(modulo -13 4)` returns `-1` on WASM but should return `3`. The conformance test at chibi-r5rs.scm:185 already expects the correct value. Additionally, ECE lacks `quotient`, `remainder`, `floor`, `truncate`, `ceiling`, and `round` — all standard R7RS operations. `quotient` is needed for `number->string` (digit extraction), which is a prerequisite for the larger Layer 2 kernel minimization effort.

## What Changes

- Add `truncate` and `floor` as new core primitives (IDs 108, 109) in both CL and WASM runtimes
- Implement `quotient`, `remainder`, `modulo`, `ceiling`, and `round` in native ECE (prelude.scm)
- **BREAKING**: Migrate `modulo` from core primitive (ID 4) to ECE-derived — fixes sign semantics on WASM for negative operands
- Remove host `modulo` implementations from both CL and WASM runtimes after bootstrap migration

## Capabilities

### New Capabilities
- `integer-rounding`: Core `truncate` and `floor` primitives on both hosts, plus ECE-derived `quotient`, `remainder`, `ceiling`, and `round`

### Modified Capabilities
- `ece-level-primitives`: `modulo` moves from host-implemented core to ECE-derived (platform tag `core` → `ece` in primitives.def)

## Impact

- **primitives.def**: Add IDs 108 (`truncate`), 109 (`floor`); change ID 4 (`modulo`) from `core` to `ece`
- **src/runtime.lisp**: Add `truncate`/`floor` wrappers; remove `(modulo . mod)` from primitive-procedures
- **wasm/runtime.wat**: Add `truncate`/`floor` dispatch; remove `i32.rem_s` dispatch for ID 4
- **src/prelude.scm**: New integer arithmetic section with 5 definitions; boot ordering change (modulo must precede even?)
- **bootstrap/**: Two-pass rebuild required for primitive migration
- **tests/**: New arithmetic tests for all 7 operations including negative operands and banker's rounding
