## Why

`string->number` currently uses CL's `read-from-string`, which is a full Lisp reader. This is unsafe (reader macros, readtable interference) and has wrong semantics (e.g., `"3/4"` returns a CL ratio). A dedicated parser avoids these issues.

## What Changes

- Replace `ece-string->number` internals with `parse-integer` for integers and a simple float parser for decimals
- No API change — `(string->number "42")` still works, `(string->number "abc")` still returns `()`
- Now also correctly handles `"3.14"` as a float without invoking the CL reader
- `"3/4"` and other CL-specific syntax correctly returns `()` (not a valid ECE number)

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `string-ops`: `string->number` implementation changes from `read-from-string` to dedicated parser, tightening what counts as a valid number

## Impact

- `src/ece.lisp`: Replace `ece-string->number` implementation
- `tests/ece.lisp`: Add tests for edge cases (floats, ratios, reader exploits)
