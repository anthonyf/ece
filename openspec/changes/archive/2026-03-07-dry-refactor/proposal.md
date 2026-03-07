## Why

The evaluator's `src/main.lisp` has three areas where code is duplicated or follows repetitive boilerplate patterns. Consolidating these makes the codebase easier to maintain and extend — every time a primitive is added, the alist must be updated in two identical places, and every new special form requires a nearly-identical predicate function.

## What Changes

- **Consolidate duplicate primitive alist**: `*primitive-procedure-names*` and `*primitive-procedure-objects*` contain the exact same 40-entry alist. Define the alist once as `*primitive-procedures*` and derive both lists from it.
- **Replace special form predicates with a single generator**: The 10 predicates (`assignment-p`, `quoted-p`, `lambda-p`, `begin-p`, `if-p`, `callcc-p`, `define-p`, `apply-form-p`, `define-macro-p`, `quasiquote-p`) all follow the pattern `(and (listp expr) (eq (car expr) 'SYMBOL))`. Replace them with a macro or function that generates predicates from the `*special-forms*` list.
- **Simplify dolist primitive registration**: The dolist block (lines 358-385) uses verbose `(cons 'name (list 'primitive 'sym))` for each entry. Restructure to use the same dotted-pair alist format as the main primitive list, with a helper that wraps each entry into `(name . (primitive sym))`.

## Capabilities

### New Capabilities
- `dry-primitives`: Consolidate the duplicate primitive alist into a single source of truth and simplify the dolist registration block.
- `dry-special-form-predicates`: Replace 10 boilerplate predicate functions with a generated approach using `*special-forms*`.

### Modified Capabilities

## Impact

- `src/main.lisp` — All changes are internal refactoring. No behavioral changes to the evaluator, no API changes, no new exports.
- `tests/main.lisp` — No test changes required since behavior is unchanged. Existing tests serve as regression coverage.
