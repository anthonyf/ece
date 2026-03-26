## Why

Save/load continuation is the cornerstone of ECE's interactive fiction architecture — it enables game save/restore via `call/cc`. The serializer (`serialize-value`) and deserializer (`deserialize-value`) handle continuations, and the file I/O primitives (`save-continuation!` / `load-continuation`) work. However, **invoking a loaded continuation fails on WASM**.

Quick test reveals:
- `save-continuation!` with a `call/cc` continuation: PASS
- `load-continuation`: PASS (returns an object)
- `(continuation? loaded-k)`: returns `#f` — the loaded object is NOT recognized as a continuation
- `(loaded-k value)`: crashes with `illegal cast`

The deserialization path (`%make-continuation` prim 164) creates a proper `$continuation` struct in isolation. The issue is in how the deserializer invokes it — either the `conts` field (space-qualified address) isn't in the right format, or the stack isn't properly reconstructed.

## What Changes

- Investigate and fix why `%make-continuation` output isn't recognized as a continuation after deserialization
- Verify the stack and conts fields are properly reconstructed (fixnum pairs, not read-form integers)
- Add WASM integration tests for the full save → load → invoke cycle
- Port the key CL continuation tests from `test-serialization.scm` to the WASM test suite

## Capabilities

### New Capabilities
_None_

### Modified Capabilities
- `save-load`: Fix continuation deserialization so loaded continuations are invokable

## Impact

- `src/prelude.scm` — likely fix in `deserialize-value` for `%ser/continuation` reconstruction
- `wasm/runtime.wat` — may need fixes in `%make-continuation` or `call_continuation`
- `tests/ece/test-roundtrip.scm` — add continuation invoke tests
