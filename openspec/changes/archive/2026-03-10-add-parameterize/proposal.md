## Why

ECE has only lexical scope, but the metacircular compiler needs dynamic scoping for `*mc-compile-lexical-env*` — a variable that tracks locally-bound names to shadow macros during compilation. Without dynamic scope, `let` bindings of this variable don't propagate to called functions (like recursive `mc-compile` calls), so macro shadowing by local `define` silently fails. R7RS Scheme solves this with `make-parameter` and `parameterize` (SRFI-39), providing opt-in dynamic binding that is safe with `call/cc`. ECE should have this too for correctness and completeness.

## What Changes

- Add `make-parameter` primitive: creates a parameter object (a procedure closing over a mutable cell) that returns its value when called with 0 args and sets it when called with 1 arg
- Add `parameterize` macro: dynamically rebinds parameter objects for the extent of a body, with proper save/restore semantics
- Refactor `*mc-compile-lexical-env*` in `compiler.scm` to use `make-parameter` / `parameterize` instead of broken lexical `let` rebinding
- Export new symbols from the ECE package

## Capabilities

### New Capabilities
- `parameterize`: Parameter objects (`make-parameter`) and dynamic rebinding (`parameterize`) per R7RS / SRFI-39

### Modified Capabilities
- `metacircular-compiler`: `*mc-compile-lexical-env*` changes from a plain global variable to a parameter object, fixing macro shadowing in the MC compiler

## Impact

- `src/runtime.lisp`: New `ece-make-parameter` primitive function
- `src/prelude.scm`: New `parameterize` macro definition
- `src/compiler.scm`: Refactor `*mc-compile-lexical-env*` to use parameter objects
- `tests/ece.lisp`: New tests for `make-parameter`, `parameterize`, and MC compiler macro shadowing
