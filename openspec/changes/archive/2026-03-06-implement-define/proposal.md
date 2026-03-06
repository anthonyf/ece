## Why

There's currently no way to bind names at the top level in ECE — the only binding mechanism is `lambda` parameters. This forces awkward self-passing patterns for recursion and makes it impossible to build up a program from named definitions. `define` is the fundamental binding form in Scheme/Lisp and is needed before the language is practically usable.

## What Changes

- Refactor the environment from a flat alist to SICP's frame-based representation (list of frames, each frame a mutable cons of parallel variable/value lists)
- Add `define` as a new special form that binds a variable in the first frame of the current environment
- Support two syntaxes: `(define x 10)` for values and `(define (f x) body...)` as shorthand for `(define f (lambda (x) body...))`
- `define` mutates the current environment's first frame, following SICP's `define-variable!`
- Export `define` from the `ece` package

## Capabilities

### New Capabilities
- `define-special-form`: The `define` special form for variable/function binding

### Modified Capabilities

## Impact

- `src/main.lisp`: Refactor environment to frame-based, update `env-lookup`, update `compound-apply` to use `extend-environment`, add `define-p` predicate, `define` to `*special-forms*`, continuation handlers, export `define`
- `tests/main.lisp`: Update tests for frame-based environments, add tests for `define`
- `README.md`: Update primitive list and examples to reflect `define`
