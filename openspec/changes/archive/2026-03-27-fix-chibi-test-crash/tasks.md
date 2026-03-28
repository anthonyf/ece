## 1. Fix

- [x] 1.1 Fix the `let` macro in `src/prelude.scm` — change `(symbol? bindings)` to `(and (symbol? bindings) (not (null? bindings)))` to handle `(let () ...)` correctly.
- [x] 1.2 Run `make bootstrap` to regenerate `bootstrap/prelude.ecec`.

## 2. Enable Chibi Tests

- [x] 2.1 Uncomment the Chibi R5RS test loading in `tests/conformance/run-conformance.scm`.
- [x] 2.2 Run `make test-conformance` and document pass/fail results.

## 3. Verify

- [x] 3.1 Verify existing tests still pass (common suite, 0 failures).
- [x] 3.2 Verify `(let () 42)` works at the top level and from macro expansion.
