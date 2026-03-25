## Why

In standard Scheme, `write` and `display` have different output rules:
- `display` outputs strings without quotes: `(display "hello")` → `hello`
- `write` outputs strings with quotes: `(write "hello")` → `"hello"`

On WASM, both `write` (prim 58) and `display` (prim 57) call the same `$display-value` function, which uses display semantics. This means `write` doesn't quote strings, breaking the Scheme spec and making `write` output non-readable (strings and symbols are indistinguishable).

## What Changes

- Make `write` (prim 58) use `$write-to-string-impl` to build the string representation, then display it. This produces quoted strings, quoted chars (`#\a`), and proper list structure.
- `display` (prim 57) remains unchanged — display semantics (no quoting).
- Same for port variants: `write` to a port should quote strings, `display` to a port should not.

## Capabilities

### New Capabilities
_None_

### Modified Capabilities
- `write-to-string`: `write` output will now match `write-to-string` output

## Impact

- `wasm/runtime.wat` — change prim 58 handler to use `$write-to-string-impl` + display the result
- `wasm/runtime.wat` — add `$write-to-port` variant that quotes strings
- `tests/ece/test-types.scm` or `test-roundtrip.scm` — add tests verifying `write` quotes strings
