## Why

`qq-expand` does not track quasiquote nesting depth. When a quasiquote appears inside another quasiquote, inner `unquote` forms are incorrectly evaluated at the outer level instead of being preserved as literal `(unquote ...)` forms. This breaks macro-writing macros and any code that constructs quasiquote templates programmatically.

## What Changes

- Rewrite `qq-expand` to accept a depth parameter that tracks nesting level
- Increment depth on encountering `quasiquote`, decrement on `unquote`/`unquote-splicing`
- Only evaluate unquoted expressions when depth reaches 0
- At depth > 0, preserve `quasiquote`/`unquote`/`unquote-splicing` as literal structure

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `quasiquote`: add requirement for nested quasiquote support with correct depth tracking

## Impact

- `src/main.lisp` — rewrite `qq-expand` function
- `tests/main.lisp` — add nested quasiquote tests
