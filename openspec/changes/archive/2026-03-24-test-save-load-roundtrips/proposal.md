## Why

The `$frame-append` bug (PR #41) was blocking serialization of proper lists on WASM. Now that it's fixed, `serialize-value` and `deserialize-value` work correctly. The existing integration tests only check types (is the result a string? is it boolean?), not semantic correctness. We need round-trip tests that verify the serialized output can be read back and produces `equal?` values — for all ECE types including continuations.

## What Changes

- Add WASM integration tests for `serialize-value` / `deserialize-value` round-trips across all ECE types: fixnums, strings, symbols, booleans, nil, pairs, proper lists, nested lists, vectors, compiled procedures, continuations
- Add integration tests for `save-continuation!` / `load-continuation` file-based round-trips
- Verify round-trips work for shared structure (values appearing multiple times in a tree)
- Remove or tighten the existing type-only serialization tests in favor of semantic equality checks

## Capabilities

### New Capabilities

- `save-load-roundtrip-tests`: Integration tests verifying that save/load and serialize/deserialize produce correct round-trip results on WASM

### Modified Capabilities

_None_ — the existing `save-load` and `value-serialization` specs describe the required behavior; this change only adds test coverage.

## Impact

- `wasm/test.js` — new integration tests added
- No runtime or prelude changes expected
