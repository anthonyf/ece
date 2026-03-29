## Why

`number->string` (ID 30) is currently implemented in both host runtimes (~60 lines of WAT, 2 lines of CL) but can be expressed entirely in ECE using `quotient`, `modulo`, `integer->char`, and `string-append` — all available since the arithmetic-foundation change. This is the next step in Layer 2 kernel minimization, following the pattern established by that change: add minimal axioms to the host, derive higher-level operations in ECE.

## What Changes

- Implement `number->string` in `prelude.scm` using digit extraction via `quotient`/`modulo` and character conversion via `integer->char`
- Remove `number->string` from CL host dispatch (`runtime.lisp`)
- Remove `number->string` from WASM primitive dispatch (ID 30 in `apply-primitive`)
- Keep `$prim-number-to-string` in WAT as a **private internal function** — `write-to-string-impl` and `display-to-port` call it directly and cannot easily invoke ECE-compiled code from within WAT. Full WAT removal is blocked until `write-to-string`/`display` are also migrated to ECE.
- Update `primitives.def` platform from `core` to `ece`

## Capabilities

### New Capabilities

- `ece-number-to-string`: ECE-derived `number->string` handling zero, positive integers, and negative integers via digit extraction loop

### Modified Capabilities

- `ece-level-primitives`: `number->string` (ID 30) moves from host-implemented core to ECE-derived

## Impact

- **src/prelude.scm**: New `number->string` definition in the integer arithmetic section (after `quotient`/`modulo`, before `gensym` which depends on it)
- **src/runtime.lisp**: Remove `ece-number->string` function and `(number->string . ece-number->string)` from `*wrapper-primitives*`
- **wasm/runtime.wat**: Remove ID 30 dispatch from `apply-primitive`; rename `$prim-number-to-string` to signal it is internal-only
- **primitives.def**: Change ID 30 from `core` to `ece`
- **bootstrap/**: Two-pass rebuild required (standard primitive migration pattern)
- **tests/**: Existing number->string tests should pass unchanged; add edge case tests for negative numbers and zero
