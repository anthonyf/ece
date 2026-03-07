## Why

ECE is missing several essential Scheme primitives that are commonly needed for real programs: `error` for signaling errors, `assoc`/`member` for association list and membership lookups, `list-ref`/`list-tail` for indexed list access, and string comparison predicates. These are all small additions with high utility.

## What Changes

- Add `error` primitive that signals an error with a message string
- Add `assoc` and `member` list search primitives
- Add `list-ref` and `list-tail` for indexed list access
- Add string comparison predicates: `string=?`, `string<?`, `string>?`, `string<=?`, `string>=?`
- Export all new symbols from the ECE package

## Capabilities

### New Capabilities
- `error-signaling`: The `error` primitive for raising errors from ECE programs
- `list-search`: `assoc` and `member` for searching lists
- `list-indexing`: `list-ref` and `list-tail` for positional list access
- `string-comparisons`: String comparison predicates (`string=?`, `string<?`, etc.)

### Modified Capabilities

## Impact

- `src/main.lisp`: New primitives and exports
- `tests/main.lisp`: New test cases for all additions
