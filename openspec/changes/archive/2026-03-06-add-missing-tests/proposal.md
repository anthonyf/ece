## Why

The evaluator implements several features — `begin`, string self-evaluation, primitive procedures (`/`, `=`, `<`, `>`, `<=`, `>=`, `car`, `cdr`, `cons`, `list`, `null?`, `not`), multi-body lambdas, and nested applications — that have no test coverage. Adding tests ensures correctness and prevents regressions as the evaluator grows.

## What Changes

- Add tests for `begin` expressions (sequential evaluation, returning last value)
- Add tests for string self-evaluation
- Add tests for all untested primitive procedures
- Add tests for multi-body lambda expressions
- Add tests for nested function application
- Add tests for error cases (unknown expression types, unknown procedure types)

## Capabilities

### New Capabilities
- `begin-tests`: Tests for the `begin` special form (sequence evaluation)
- `string-eval-tests`: Tests for string self-evaluation
- `primitive-proc-tests`: Tests for all primitive procedures not yet covered
- `advanced-lambda-tests`: Tests for multi-body lambdas and nested application
- `error-case-tests`: Tests for error signaling on invalid inputs

### Modified Capabilities

## Impact

- `tests/main.lisp`: New test definitions added
- No changes to source code; test-only change
