## Why

Seven core primitives are purely algorithmic — they can be expressed entirely in ECE using other primitives, with no host-specific type checks or memory layout access. Migrating them continues the Layer 2 kernel minimization effort, shrinking the CL and WASM runtimes and reducing the surface area for the WASM port.

## What Changes

- Implement in `prelude.scm`:
  - `char=?` (45) — `(= (char->integer a) (char->integer b))`
  - `char<?` (46) — `(< (char->integer a) (char->integer b))`
  - `string=?` (33) — character-by-character equality via `string-ref`, `char=?`
  - `string<?` (34) — lexicographic comparison via `string-ref`, `char<?`
  - `string>?` (35) — reverse of `string<?`
  - `vector->list` (55) — index loop building list with `vector-ref`, `cons`
  - `list->vector` (56) — count + `make-vector` + `vector-set!` loop
- Remove all seven from CL `*wrapper-primitives*` and their CL functions
- Remove all seven from WASM `$apply-primitive` dispatch
- Keep WAT functions `$prim-string-eq` and `$prim-list-to-vector` as internal helpers (called by `$prim-equal` and `vector` primitive respectively)
- Update `primitives.def` platform from `core` to `ece`
- Regenerate `wasm/primitives.json`

## Capabilities

### New Capabilities

- `ece-trivial-primitives`: ECE-derived implementations of char comparisons, string comparisons, and vector conversions

### Modified Capabilities

- `ece-level-primitives`: Seven additional primitives move from host-implemented to ECE-derived

## Impact

- **src/prelude.scm**: 7 new definitions in appropriate sections (char predicates section, string section, vector section)
- **src/runtime.lisp**: Remove 7 functions and their `*wrapper-primitives*` entries
- **wasm/runtime.wat**: Remove 7 dispatch cases from `$apply-primitive`; keep `$prim-string-eq`, `$prim-string-lt`, `$prim-list-to-vector` as internal helpers
- **primitives.def**: Change 7 IDs from `core` to `ece`
- **wasm/primitives.json**: Regenerated (7 entries removed)
- **bootstrap/**: Two-pass rebuild
