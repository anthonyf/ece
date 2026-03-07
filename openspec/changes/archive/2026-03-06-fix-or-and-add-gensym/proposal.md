## Why

The `or` macro evaluates its first truthy argument twice: `(if (car args) (car args) ...)`. This means `(or (begin (display "hi") 1) 2)` prints "hi" twice. Fixing this properly requires `let` with a temporary variable, but the temp variable name must be unique to avoid capture — which requires `gensym`.

## What Changes

- Add `gensym` as a primitive procedure that generates unique symbols
- Fix the `or` macro to use `let` + `gensym` so truthy values are only evaluated once
- Fix the `and` macro similarly (it has the same double-evaluation pattern in the truthy case isn't an issue since `and` returns the last value, but for consistency and to avoid subtle bugs with side effects)

## Capabilities

### New Capabilities
- `gensym`: gensym primitive for generating unique symbols

### Modified Capabilities
- `define-macro`: fix the `or` macro to not double-evaluate its first truthy argument

## Impact

- `src/main.lisp` — add gensym primitive, rewrite `or` macro
- `tests/main.lisp` — add gensym tests, add or double-evaluation regression test
