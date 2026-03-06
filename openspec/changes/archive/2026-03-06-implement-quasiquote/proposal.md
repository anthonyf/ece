## Why

Macro definitions currently require verbose `(list (quote if) ...)` constructions to build output forms. Quasiquote (`` ` ``, `,`, `,@`) is the standard way to write template-based code generation in Lisp, making macros dramatically more readable. With `define-macro` now in place, quasiquote is the natural next step.

## What Changes

- Add `quasiquote` as a special form that transforms a template into list-construction expressions (`cons`/`append`) and re-dispatches
- Handle `(unquote expr)` within templates — evaluates `expr` and inserts the value
- Handle `(unquote-splicing expr)` within templates — evaluates `expr` and splices the resulting list
- Set up a custom readtable for ECE reading so `` ` ``, `,`, and `,@` produce `quasiquote`/`unquote`/`unquote-splicing` forms in the REPL

## Capabilities

### New Capabilities
- `quasiquote`: Quasiquote template expansion with unquote and unquote-splicing

### Modified Capabilities

## Impact

- `src/main.lisp`: Add `quasiquote-p` predicate, `qq-expand` transformation function, `ev-quasiquote` handler, custom readtable for `ece-read`, export new symbols
- `tests/main.lisp`: Add tests for quasiquote, unquote, and unquote-splicing
