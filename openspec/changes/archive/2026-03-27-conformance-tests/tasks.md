## 1. Conformance Test Runner

- [x] 1.1 Create `tests/conformance/conformance-framework.scm` — minimal test framework with pass/fail/skip counters, `conformance-test` macro, `skip-test` mechanism, and summary printer.
- [x] 1.2 Create `tests/conformance/run-conformance.scm` — entry point that loads the framework and all test suites, then prints results.

## 2. R5RS Pitfall Tests

- [x] 2.1 Write `tests/conformance/r5rs-pitfall.scm` — adapted from published R5RS pitfall cases. Cover: tail-call correctness, continuation + dynamic-wind interactions, `let`/`letrec` semantics, `map`/`for-each` with multiple lists. Use `conformance-test` macro for each case.
- [x] 2.2 Run pitfall tests, document which pass and which fail, skip any that use unsupported features.

## 3. Chibi R5RS Tests

- [x] 3.1 Fetch and adapt `tests/conformance/chibi-r5rs.scm` from upstream Chibi source. Minimal changes: remove `import` if present, stub or replace `call-with-output-string`/`flush-output` in the framework preamble. Keep test cases verbatim.
- [x] 3.2 Run Chibi R5RS tests, document which pass and which fail, skip any that use unsupported features.

## 4. Build Integration

- [x] 4.1 Add `test-conformance` target to Makefile that loads and runs `tests/conformance/run-conformance.scm` in a separate SBCL session.
- [x] 4.2 Add `test-conformance` step to `.github/workflows/test.yml` with `continue-on-error: true`.

## 5. Verification

- [x] 5.1 Run `make test-conformance` locally, verify summary output and exit code.
- [x] 5.2 Verify existing tests still pass (`make test-ece` and Rove tests unaffected).
