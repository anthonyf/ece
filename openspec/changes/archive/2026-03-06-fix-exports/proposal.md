## Why

Several ECE-specific symbols (`display`, `newline`, `null?`, `eof?`, `primitive`) are not exported from the `ece` package, forcing tests to use `ece::` internal access. Exporting these symbols and cleaning up the tests makes the code more consistent and idiomatic.

## What Changes

- Export `display`, `newline`, `null?`, `eof?`, and `primitive` from the `ece` package
- Remove all unnecessary `ece::` prefixes in tests (symbols already exported or newly exported)

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- `src/main.lisp`: Add symbols to package exports
- `tests/main.lisp`: Replace `ece::` prefixes with unqualified symbols
