## 1. Fix representation-leaking test assertions

- [x] 1.1 In `tests/ece/test-callcc-tco.scm`, replace `(pair? result)` / `(car result)` assertions with `(continuation? result)` — use `(assert-true (continuation? result))` instead of `(assert (pair? result) ...)` / `(assert-equal (car result) 'continuation)`
- [x] 1.2 In `tests/ece/test-serialization.scm`, replace any `(pair? k)` / `(car k)` assertions on continuations with `(continuation? k)`
- [x] 1.3 Run CL tests (`make test-ece`) to verify assertions still pass with abstract predicates

## 2. Cross-platform assert-error

- [x] 2.1 Rewrite `assert-error` macro in `tests/ece/test-framework.scm` to use `guard` instead of `try-eval`
- [x] 2.2 Audit `tests/ece/test-errors.scm` — remove any `(when (platform-has? 'try-eval) ...)` guards that are no longer needed
- [x] 2.3 Audit `tests/ece/test-error-messages.scm` — same: remove unnecessary platform guards
- [x] 2.4 Run CL tests to verify error tests still pass with the guard-based implementation

## 3. Fix WASM tail-position call/cc TCO

- [x] 3.1 Create minimal reproduction: compile a 3-iteration tail-position call/cc loop, run on WASM with trace output enabled to identify where stack frames accumulate
- [x] 3.2 Diagnose the WASM dispatch issue — check whether `(goto (reg continue))` correctly handles space-qualified addresses when continue was set by `capture-continuation`
- [x] 3.3 Fix the WASM runtime (`wasm/runtime.wat`) to handle the tail-position call/cc instruction pattern
- [x] 3.4 Verify the fix: run the 10,000-iteration tail-position call/cc test on WASM successfully

## 4. Unify test manifests

- [x] 4.1 Add `platform-has?` guards to `test-errors.scm` for any tests that truly need CL-only features (if any remain after task 2)
- [x] 4.2 Add `platform-has?` guards to `test-error-messages.scm` similarly
- [x] 4.3 Verify `test-file-io.scm` already has adequate guards (it should)
- [x] 4.4 Move `test-callcc-tco.scm` back into the shared suite — remove CL-only comment header
- [x] 4.5 Update `run-common.scm` to include all test files (add `test-errors.scm` and `test-error-messages.scm` if not already present)
- [x] 4.6 Update `Makefile` — derive `WASM_TEST_SRCS` from `run-common.scm` or replace the hardcoded list with a script that parses it
- [x] 4.7 Run both `make test-ece` and `make test-wasm` to verify both platforms execute the same test files

## 5. Make conformance tests blocking

- [x] 5.1 Remove `continue-on-error: true` from the conformance test step in `.github/workflows/test.yml`
- [x] 5.2 Verify conformance tests pass locally: `make test-conformance`

## 6. Test-count regression check

- [x] 6.1 Create `tests/test-counts.json` with current baseline counts for all suites (CL ECE, CL rove, WASM ECE, WASM integration, conformance)
- [x] 6.2 Add a CI step that runs after all test suites, parses their output for pass counts, and compares against baselines
- [x] 6.3 Add `make update-test-counts` target that runs all suites and updates the baselines file
- [x] 6.4 Verify CI fails when a test count drops (test by temporarily lowering a baseline)

## 7. Final validation

- [x] 7.1 Run full CI pipeline locally: `make test`, `make test-wasm`, `make test-conformance`
- [x] 7.2 Verify WASM and CL test counts match expectations (both running the same test files)
- [x] 7.3 Verify no test files are silently excluded from either platform
