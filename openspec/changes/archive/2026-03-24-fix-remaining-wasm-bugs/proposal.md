## Why

Three WASM runtime bugs surfaced during the serialization round-trip work. They affect correctness of `equal?`, `write-to-string`, and `define-variable!` on the WASM runtime.

## What Changes

### Bug 1: Late top-level define crash
Any `(define ...)` appearing late in a large `.ecec` file crashes. Defining the same function early in the file works. Root cause: `define-variable!` calls `frame-append` on the global env, and the names-list/vals-array handling breaks when the global frame is very large. Needs investigation — may require pre-allocating global env slots or fixing `frame-append` for the global env case.

### Bug 2: String serialization missing quotes
`$write-to-string-impl` returns strings without quoting (line 2740: returns the string object directly). For `write`-style output, strings must be wrapped in `"..."` with escape handling for `\` and `"` characters. This breaks `serialize-value` round-trips for strings.

### Bug 3: Vector `equal?`
`$prim-equal` handles identity, fixnums, strings, pairs, and numbers but does NOT descend into vectors. `(equal? (vector 1 2 3) (vector 1 2 3))` returns `#f`. Need to add element-wise vector comparison.

## Capabilities

### New Capabilities
_None_

### Modified Capabilities
- `value-serialization`: String round-trips will work after write-to-string fix
- `predicates-and-equality`: `equal?` will handle vectors

## Impact

- `wasm/runtime.wat` — `$write-to-string-impl` (string quoting), `$prim-equal` (vector case), `$define-variable!` / `$frame-append` (large global env)
- `tests/ece/test-roundtrip.scm` — enable string and vector round-trip tests
- `wasm/test.js` — may update integration tests
