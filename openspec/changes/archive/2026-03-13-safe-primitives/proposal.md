## Why

ECE primitives delegate directly to CL functions (`+`, `car`, `/`, etc.). When a user passes wrong types — `(+ "a" 1)`, `(car 5)`, `(/ 1 0)` — CL signals a condition that bypasses ECE's exception system entirely. `guard` cannot catch these errors. By adding type-checking wrappers in the ECE prelude, errors are raised through ECE's `error`/`raise`/`guard` mechanism, making them catchable, producing better error messages, and eliminating CL error leakage from user code.

## What Changes

- Rename error-prone primitives in `*primitive-procedures*` to `%raw-` prefixed names (e.g., `+` → `%raw-+`, `car` → `%raw-car`)
- Define safe wrappers in `src/prelude.scm` that type-check arguments then call the raw primitive
- Wrappers call ECE `error` on type mismatch, which flows through `raise`/`guard` naturally
- Safe primitives only for operations that can actually produce CL type errors; predicates (`null?`, `pair?`, `number?`, etc.), constructors (`cons`, `list`), and `eq?`/`equal?` are left as-is
- Update ECE native tests to cover type error catching via `guard`

Primitives to wrap:
- **Arithmetic**: `+`, `-`, `*`, `/`, `=`, `<`, `>`, `mod`, `abs`, `min`, `max`
- **Bitwise**: `bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift`
- **List access**: `car`, `cdr`
- **String comparison**: `string=?`, `string<?`, `string>?`
- **Char ops**: `char=?`, `char<?`, `char->integer`, `integer->char`
- **Vector access**: `vector-ref`, `vector-length`

## Capabilities

### New Capabilities
- `safe-primitives`: Type-checking wrappers for error-prone primitives in the ECE prelude

### Modified Capabilities
- `error-signaling`: CL-originated type errors are now catchable by `guard` via ECE's error system

## Impact

- `src/runtime.lisp`: Rename ~25 entries in `*primitive-procedures*` to `%raw-` prefixed names
- `src/prelude.scm`: Add ~60-80 lines of safe wrapper definitions
- `tests/ece/test-error-messages.scm`: Add tests for type error catching via `guard`
- `bootstrap/ece.image`: Must be regenerated after prelude changes
- Zero executor changes. Zero bridging mechanism. Pure ECE solution.
