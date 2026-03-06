## Why

The `if` special form is a fundamental conditional construct needed for any non-trivial program. The evaluator already has stubbed-out continuation handlers for `if` (`:ev-if`, `:ev-if-decide`, `:ev-if-consequent`, `:ev-if-alternative`) but they contain no implementation. Without `if`, the language cannot express conditional logic.

## What Changes

- Implement the `if` special form in the evaluator's continuation handlers
- Support the form `(if predicate consequent alternative)` with an optional alternative (defaults to nil)
- Add comprehensive tests for `if` expressions

## Capabilities

### New Capabilities
- `if-special-form`: Implementation and tests for the `if` conditional expression

### Modified Capabilities

## Impact

- `src/main.lisp`: Fill in the `:ev-if`, `:ev-if-decide`, `:ev-if-consequent`, and `:ev-if-alternative` continuation handlers
- `tests/main.lisp`: New test definitions for `if`
