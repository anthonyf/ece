## Why

The evaluator has `define` for creating new bindings but no way to mutate existing ones. `set!` is Scheme's assignment operator — it updates an existing variable's value across all frames, signaling an error if the variable is unbound. This is the last missing special form from SICP's explicit control evaluator.

## What Changes

- Implement `set!` as a special form that updates an existing binding in the environment
- Add `set-variable-value!` environment operation (scans all frames, unlike `define-variable!` which only touches the first)
- Wire up the existing `assignment-p` predicate and `set` special form registration (both already exist but have no handler)

## Capabilities

### New Capabilities
- `set-special-form`: The `set!` special form for variable mutation

### Modified Capabilities

## Impact

- `src/main.lisp`: Add `set-variable-value!`, add `ev-assignment` and `ev-assignment-assign` continuation handlers, add dispatch clause
- `tests/main.lisp`: Add tests for `set!`
