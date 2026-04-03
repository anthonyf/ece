## Why

The WASM runtime's instruction assembler walks S-expression lists using `(call $car (ref.cast (ref $pair) ...))` chains. The `ref.cast` is required by WASM GC's type system but is pure boilerplate — 182 call sites for simple car/cdr, plus 16 `cadr` and 4 `caddr` compositions. Adding casting `$xcar`/`$xcdr` helpers and composed `$cadr`/`$caddr` helpers would eliminate the casts at call sites and make the WAT readable.

## What Changes

- **Add casting car/cdr helpers**: `$xcar` and `$xcdr` that take `(ref null eq)`, cast to `$pair` internally, and return `(ref null eq)`. Eliminates `ref.cast` at 182 call sites.
- **Add composed accessors**: `$cadr` and `$caddr` built on the casting helpers. Replaces 16 and 4 multi-line patterns respectively.
- **Rewrite call sites**: Replace all `(call $car (ref.cast (ref $pair) ...))` with `(call $xcar ...)` and compositions with `$cadr`/`$caddr`.

## Capabilities

### New Capabilities
- `wat-cxr-helpers`: Casting car/cdr helper functions and composed list accessors for WASM runtime.

### Modified Capabilities

## Impact

- **`wasm/runtime.wat`**: ~200 call sites rewritten. Net line reduction. No behavioral change — all helpers are pure wrappers.
- **No .ecec changes**: Helpers are internal to the WAT runtime.
- **No CL changes**: WASM-only.
