## Why

12 tests across the ECE test suite are either commented out or broken. The `make test` target also fails because the Makefile references a non-existent rove API (`suite-stats`), causing the rove runner to crash after all 120 tests pass. Every disabled test should either be fixed or have a clear, documented technical reason for remaining disabled.

## What Changes

- **Fix rove test runner crash**: Replace broken `rove/core/suite::suite-stats` call in Makefile with the correct `rove:run` API so `make test-rove` exits cleanly.
- **Fix `keyword?` for ECE keywords**: Implement ECE-native `keyword?` that checks for symbols named `":..."` rather than delegating to CL's `keywordp` (which never matches ECE keywords). Uncomment 1 test.
- **Fix `platform-has?` inconsistency**: Normalize CL return value — currently returns `()` for unknown (Scheme-truthy) while WASM returns `#f`. Uncomment 2 tests.
- **Fix hash table serialization**: Add `hash-table?` branch to `serialize-value` so CL native hash tables round-trip correctly. Uncomment 1 test.
- **Fix `write-compiled-unit` label scoping**: Investigate and fix label resolution when `write-compiled-unit` is called from within a compiled context. Uncomment 2 tests.
- **Fix continuation serialization under `parameterize`**: The ece-test runner's `parameterize` isolation captures non-serializable CL objects (ports, closures) in continuation frames. Either teach the serializer to handle/skip these frames, or provide a way to run these specific tests without isolation. Uncomment 6 tests.

## Capabilities

### New Capabilities

_None — all fixes are to existing capabilities._

### Modified Capabilities

- `ece-test-runner`: Rove Makefile target must exit with correct status
- `value-serialization`: Hash table serialization support; continuation serialization must handle parameterize frames
- `compiled-unit`: `write-compiled-unit` / `read-compiled-unit` round-trip must work from compiled contexts
- `platform-discovery`: `platform-has?` must return `#f` (not `()`) for unknown primitives on all platforms
- `predicates-and-equality`: `keyword?` must recognize ECE keywords (`:foo` style symbols)

## Impact

- **Makefile** (`Makefile:90-94`): rove runner invocation
- **Serialization** (`src/prelude.scm`): `serialize-value`, hash table and parameterize frame handling
- **Compilation units** (`src/compilation-unit.scm` or equivalent): label resolution in `write-compiled-unit`
- **Primitives** (`src/primitives.lisp` or equivalent): `keyword?`, `platform-has?` return values
- **Tests**: 12 commented-out tests across `test-serialization.scm`, `test-compilation-units.scm`, `test-misc.scm`
