## 1. Pattern Matcher

- [x] 1.1 Implement `syntax-match` — match an expression against a pattern, returning an alist of bindings or `#f`. Handle: pattern variables, literal matching, `_` wildcard, nested list patterns.
- [x] 1.2 Add ellipsis pattern support to `syntax-match` — when `...` follows a pattern variable, collect zero or more repetitions into a list binding. Handle ellipsis with fixed prefix elements.

## 2. Template Instantiation

- [x] 2.1 Implement `syntax-instantiate` — walk a template, replacing pattern variables with their matched bindings. Introduce gensym for identifiers not in the pattern (hygiene).
- [x] 2.2 Add ellipsis template support to `syntax-instantiate` — when `...` follows a template element, replicate it once for each entry in the corresponding ellipsis binding list.

## 3. syntax-rules and define-syntax Forms

- [x] 3.1 Implement `syntax-rules` — given literals and clauses, produce a lambda that tries each clause's pattern via `syntax-match`, then instantiates the first matching template via `syntax-instantiate`. Signal error if no clause matches.
- [x] 3.2 Implement `define-syntax` as a `define-macro` that evaluates its second argument (a `syntax-rules` form) and registers the resulting transformer via `define-macro`.

## 4. Boot Integration

- [x] 4.1 Create `src/syntax-rules.scm` containing all of the above.
- [x] 4.2 Add `syntax-rules` to the bootstrap sequence — update `boot-from-compiled` in `runtime.lisp` to load `syntax-rules.ecec` after `compilation-unit.ecec`. Update `BOOTSTRAP_SRCS` in `Makefile`.
- [x] 4.3 Run `make bootstrap` to generate `bootstrap/syntax-rules.ecec`.

## 5. Tests

- [x] 5.1 Create `tests/ece/test-syntax-rules.scm` with tests covering all spec scenarios: single/multi-clause matching, wildcards, literals, ellipsis (zero and multiple), hygiene (swap! with `temp`), sub-list patterns, no-match error.
- [x] 5.2 Add `test-syntax-rules.scm` to `run-common.scm` and `WASM_TEST_SRCS` in Makefile.
- [x] 5.3 Verify all tests pass on CL (`make test-ece`) and WASM (`make test-wasm`).
