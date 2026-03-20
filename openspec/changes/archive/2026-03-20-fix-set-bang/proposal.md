## Why

ECE uses `set` for variable mutation, but R7RS Scheme uses `set!`. This is the most impactful divergence from standard Scheme — any Scheme code or library using `set!` silently fails (unbound variable) instead of working. The `!` convention also signals mutation, which is a valuable Scheme idiom.

## What Changes

- **BREAKING**: Rename the `set` special form to `set!` in the compiler
- Update all `.scm` source files (`prelude.scm`, `reader.scm`, `compiler.scm`) to use `set!`
- Update `letrec` macro expansion to use `set!`
- Rebuild bootstrap `.ecec` files

## Capabilities

### New Capabilities

_None — this modifies existing behavior._

### Modified Capabilities

- `set-special-form`: Assignment form renamed from `set` to `set!`

## Impact

- **compiler.scm**: Change `mc-assignment?` to check for `set!` instead of `set`
- **prelude.scm**: ~10 uses of `(set var val)` → `(set! var val)`
- **reader.scm**: ~16 uses of `(set var val)` → `(set! var val)`
- **All .ecec files**: Must be regenerated via `make bootstrap`
- **Existing user code**: Any code using `(set var val)` must change to `(set! var val)`
