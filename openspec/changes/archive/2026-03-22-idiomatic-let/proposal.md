## Why

The ECE codebase uses `(begin (define ...) ...)` patterns extensively where idiomatic Scheme would use `let`, `let*`, or named `let`. This makes the code harder to read for Scheme programmers and obscures the scoping intent. The `let` macro is available throughout (defined at line 173 of prelude.scm), so these patterns are stylistic debt, not a technical necessity.

~100 internal `define` instances exist across the source files. Of these, ~74 should be converted: 20 named helper loops → named `let`, 54 scattered local bindings → `let`/`let*`. The remaining ~26 are multi-function blocks where internal `define` is acceptable R7RS style.

## What Changes

- Convert `(begin (define (iter ...) ...) (iter ...))` patterns to named `let` in post-prelude code
- Convert scattered `(define x expr)` local bindings to `let`/`let*` forms
- Leave multi-function blocks (e.g., `serialize-value` with its `scan`/`ser`/`ser-compound` helpers) as-is
- Leave early prelude definitions (before line 173, the `let` macro) as-is — they cannot use `let`
- Rebuild bootstrap after changes

## Capabilities

### New Capabilities

(none — this is a refactoring with no behavioral change)

### Modified Capabilities

(none — pure style cleanup, no spec-level behavior changes)

## Impact

- **prelude.scm**: ~35 scattered bindings + ~13 named loops (post-let-macro section only)
- **compiler.scm**: 3 named loops
- **assembler.scm**: 6 scattered bindings
- **compilation-unit.scm**: ~13 scattered bindings + 1 named loop
- **ecec-to-binary.scm**: 3 named loops
- **reader.scm, browser-lib.scm**: Already clean, no changes
- **Bootstrap**: Must rebuild (`make bootstrap`) after all changes
- **Risk**: Low — purely mechanical refactoring of scoping forms. Test suite catches regressions.
