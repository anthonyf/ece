## Why

Common patterns in ECE programs require verbose boilerplate. Adding concise forms for trimming strings, clamping numbers, folding, and looping with collection makes everyday code cleaner.

## What Changes

- Add `string-trim` primitive — trim whitespace from both ends of a string
- Add `clamp` function to prelude — constrain a number to a range
- Add `fold-left`, `fold-right`, and `fold` (alias for `reduce`) to prelude
- Add `loop` macro — simple infinite loop with `break` to exit with a value
- Add `collect` macro — map over a range or list, collecting results

## Capabilities

### New Capabilities
- `string-trim`: `string-trim` primitive for whitespace trimming
- `clamp`: `clamp` function to constrain numbers to a range
- `fold-functions`: `fold`, `fold-left`, `fold-right` fold functions
- `loop-collect`: `loop` macro for general looping with `break`, `collect` macro for concise list building

### Modified Capabilities

None.

## Impact

- `src/ece.lisp`: Add `string-trim` primitive and export, add `break` export for loop macro
- `src/prelude.scm`: Add `clamp`, `fold`, `fold-left`, `fold-right`, `loop`, `collect`
- `tests/ece.lisp`: Add tests for all new forms
