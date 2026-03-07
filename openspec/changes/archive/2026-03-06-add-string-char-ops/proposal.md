## Why

ECE can create string literals but has no string operations — you can't get a string's length, extract characters, concatenate, or convert between strings and other types. Characters are readable via the CL reader (`#\a`) but the evaluator doesn't recognize them as self-evaluating and has no character predicates or operations.

## What Changes

- Make characters self-evaluating (add `characterp` to `self-evaluating-p`)
- Add character primitives: `char?`, `char=?`, `char<?`, `char->integer`, `integer->char`
- Add string primitives: `string-length`, `string-ref`, `string-append`, `substring`, `string->number`, `number->string`, `string->symbol`, `symbol->string`
- Export all new symbols from the ECE package

## Capabilities

### New Capabilities
- `char-ops`: Character type support and operations
- `string-ops`: String manipulation primitives

### Modified Capabilities

## Impact

- `src/main.lisp`: Modify `self-evaluating-p`, add primitives to name/object lists, add exports
- `tests/main.lisp`: Add tests for character and string operations
