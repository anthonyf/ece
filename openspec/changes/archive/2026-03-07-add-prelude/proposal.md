## Why

ECE's stdlib (macros, higher-order functions, PRNG, utility macros) is currently defined inline in `ece.lisp` as `(evaluate '...)` calls wrapped in CL readtable switches. This mixes CL infrastructure with pure ECE code. Extracting these definitions into a `prelude.scm` file separates concerns: CL-dependent code stays in `.lisp`, pure ECE code lives in `.scm`, editable as native ECE source.

## What Changes

- Create `src/prelude.scm` containing all stdlib definitions currently written as `(evaluate '...)` calls in `ece.lisp`
- Remove the corresponding `(evaluate '...)` blocks and CL readtable switch dance from `ece.lisp`
- Add an `ece-load` call at the end of `ece.lisp` initialization to load the prelude automatically
- No behavioral changes — the same functions and macros are available at startup

## Capabilities

### New Capabilities
- `prelude-loading`: The evaluator automatically loads `prelude.scm` at system initialization, making all standard derived forms available

### Modified Capabilities

None — this is a refactor. All existing behavior is preserved.

## Impact

- `src/ece.lisp`: Remove ~180 lines of `(evaluate '...)` calls and readtable switches; add one `ece-load` call
- `src/prelude.scm`: New file containing all pure-ECE stdlib definitions
- No API changes, no new dependencies, no behavioral changes
