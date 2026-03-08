## Why

Authoring text-heavy content (room descriptions, dialogue, narrative) requires frequent string concatenation with variable substitution. Currently this requires verbose `fmt` calls or manual `string-append` chains. String interpolation and a `lines` helper make text authoring clean and readable.

## What Changes

- Add string interpolation to the ECE reader: `$var` and `$(expr)` inside strings expand to `fmt` calls at read time
- Add `lines` function to the prelude that joins strings with newlines
- `$$` produces a literal `$` in interpolated strings
- Strings without `$` remain plain strings (zero overhead)

## Capabilities

### New Capabilities
- `string-interpolation`: Reader-level string interpolation with `$var` and `$(expr)` syntax
- `lines-function`: Prelude function that joins arguments with newline separators

### Modified Capabilities

None.

## Impact

- `src/ece.lisp`: Add custom string reader to `*ece-readtable*` that handles `$` interpolation
- `src/prelude.scm`: Add `lines` function
- No breaking changes — strings without `$` behave identically to before
