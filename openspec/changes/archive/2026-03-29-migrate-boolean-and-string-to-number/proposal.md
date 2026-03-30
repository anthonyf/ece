## Why

Two more core primitives can be expressed entirely in ECE: `boolean?` (already implemented in prelude but host not yet removed) and `string->number` (digit parsing via `char->integer` and `string-ref`). Migrating them continues the Layer 2 kernel minimization, further shrinking the CL and WASM runtimes.

## What Changes

- Remove `boolean?` (19) from CL and WASM host dispatch — prelude.scm already defines it at line 95
- Implement `string->number` (29) in `prelude.scm` — parse sign, integer digits, optional decimal point and fractional digits using `char->integer`, `string-ref`, `string-length`
- Remove `string->number` from CL `*wrapper-primitives*` and its CL function
- Remove `string->number` from WASM `$apply-primitive` dispatch; remove `$prim-string-to-number` and `$parse-float-after-dot` WAT functions (no internal callers)
- Keep `$is-boolean` WAT function as internal helper (called by `$prim-write` and `$prim-equal`)
- Update `primitives.def` platform from `core` to `ece` for both
- Two-pass bootstrap

## Capabilities

### New Capabilities

- `ece-string-to-number`: ECE-derived implementation of `string->number` with integer and decimal float support

### Modified Capabilities

- `ece-level-primitives`: Two additional primitives move from host-implemented to ECE-derived

## Impact

- **src/prelude.scm**: New `string->number` definition (~25-30 lines) in "Derived predicates" or nearby section; `boolean?` already present
- **src/runtime.lisp**: Remove `ece-boolean-p`, `ece-string->number` functions and their `*wrapper-primitives*` entries
- **wasm/runtime.wat**: Remove ID 19 and 29 dispatch cases from `$apply-primitive`; remove `$prim-string-to-number` and `$parse-float-after-dot`; keep `$is-boolean` as internal helper
- **primitives.def**: Change IDs 19, 29 from `core` to `ece`
- **wasm/primitives.json**: Regenerated
- **bootstrap/**: Two-pass rebuild
