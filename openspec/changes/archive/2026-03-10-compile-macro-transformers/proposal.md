## Why

Macro transformers are currently stored as source code `(params body env)` and expanded by manually extending an environment and compiling each body form at expansion time. This is an interpreted-style approach in a compile-only system — macro transformers are just functions `sexp → sexp` and should be compiled like any other lambda. Compiling them eliminates per-expansion compilation overhead, removes source code from the image's macro table (shrinking image size), and makes the macro system consistent with the rest of the evaluator.

## What Changes

- `mc-compile-define-macro` compiles the transformer into a procedure (via `mc-compile-and-go` of a lambda) and stores the compiled procedure in the macro table instead of `(params body env)`.
- `mc-expand-macro-at-compile-time` calls the compiled transformer procedure directly instead of manually binding params, extending environments, and compiling body forms.
- The `*compile-time-macros*` table stores compiled procedures instead of source triples.
- The image serializes compiled macro procedures (entry PCs) instead of source code.
- The `define-macro` spec is updated to reflect that transformers are compiled procedures.
- The `metacircular-compiler` spec is updated to reflect the new expansion mechanism.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `define-macro`: Transformer storage changes from `(params body env)` source tuples to compiled procedures.
- `metacircular-compiler`: Macro expansion calls a compiled procedure instead of manually interpreting the transformer body.

## Impact

- `src/compiler.scm`: `mc-compile-define-macro` and `mc-expand-macro-at-compile-time` rewritten.
- `src/runtime.lisp`: `*compile-time-macros*` docstring updated (stores procedures, not source).
- `bootstrap/ece.image`: Regenerated — macro table entries are now compiled procedures.
- All existing macro tests must continue to pass unchanged.
