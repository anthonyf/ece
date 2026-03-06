## Why

Lambda currently only supports fixed parameter lists. Rest parameters (`(lambda (x y . rest) ...)`) are needed to support variadic functions — a prerequisite for `map`, `append`, and eventually `define-macro`. Without rest params, users cannot write functions that accept a variable number of arguments.

## What Changes

- Support dotted parameter lists in `lambda` and `define` shorthand: `(lambda (x y . rest) body)` binds remaining arguments to `rest`
- Update `extend-environment` to handle rest parameter binding

## Capabilities

### New Capabilities
- `rest-parameters`: Rest/variadic parameter support for lambda and define

### Modified Capabilities

## Impact

- `src/main.lisp`: Modify `extend-environment` (or add a new binding step) to detect dotted pairs in parameter lists and bind the rest parameter to remaining arguments
- `tests/main.lisp`: Add tests for rest parameters
