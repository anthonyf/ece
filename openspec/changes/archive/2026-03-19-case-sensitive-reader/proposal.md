## Why

ECE's reader currently upcases all symbol names, inheriting Common Lisp's convention. Modern Scheme (R6RS/R7RS) is case-sensitive by default. Case sensitivity enables mixed-case symbols (`myVar`, `HashMap`) and aligns ECE with standard Scheme behavior.

## What Changes

- **BREAKING**: Remove `string-upcase` from `read-symbol` and related reader functions in `reader.scm` — symbols preserve their original case
- **BREAKING**: Remove `string-upcase` from `ece-string->symbol` in `runtime.lisp` — `string->symbol` interns the string as-is
- **BREAKING**: Change `symbol->string` in `runtime.lisp` to return `symbol-name` without downcasing
- Remove `string-upcase` from CL-side space creation and primitive loading in `runtime.lisp`
- Rebuild all `.ecec` bootstrap files to use lowercase symbols

## Capabilities

### New Capabilities

_None — this modifies existing behavior._

### Modified Capabilities

- `ece-reader`: Symbol parsing changes from case-folding (upcase) to case-preserving

## Impact

- **reader.scm**: Remove `string-upcase` calls in `read-symbol`, `read-number` fallback, and string interpolation identifier reading
- **runtime.lisp**: Update `ece-string->symbol`, `ece-symbol->string`, `create-space`, `find-space-by-name`, and primitive loading to stop upcasing
- **All .scm source files**: No changes needed — source is already lowercase. After rebuild, symbols will be stored lowercase instead of uppercase.
- **All .ecec bootstrap files**: Must be regenerated via `make bootstrap` — old files contain upcased symbols
- **Tests**: Any CL-side tests that reference ECE symbols by uppercase name will need updating
- **REPL**: Symbol display will be lowercase (matching source) instead of uppercase
