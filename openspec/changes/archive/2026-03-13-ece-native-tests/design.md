## Context

ECE has 689 CL/rove test assertions. ~420 of them (74%) are pure ECE semantics — they evaluate an expression and check the result. These could run on any ECE platform. ECE already has `assert` (macro, errors on failure) and `try-eval` (CL primitive, catches errors and returns nil). The test framework needs to build on these to provide pass/fail counting and reporting.

## Goals / Non-Goals

**Goals:**
- Minimal test framework written in ECE (~30-50 lines)
- Test files organized by category as `.scm` files
- `make test-ece` target to run the suite
- Tests work on the current CL-hosted ECE and on any future runtime
- Clear pass/fail output with counts

**Non-Goals:**
- Replacing the CL/rove test suite (it stays for host integration tests)
- Test isolation (each test file runs in the shared global env — same as the CL tests)
- Async/parallel test execution
- Code coverage tooling

## Decisions

### 1. Test framework lives in a `.scm` file loaded at test time, not in the image

The framework (`tests/test-framework.scm`) is loaded before test files. It's not part of the prelude or bootstrap image — it's test infrastructure only.

**Rationale:** Keeps the image lean. The framework is only needed during testing, not at runtime. Any platform that can `load` a `.scm` file can use it.

### 2. API: `test`, `assert-equal`, `assert-true`, `assert-error`, `run-tests`

```scheme
(test "arithmetic addition" (lambda ()
  (assert-equal (+ 1 2) 3)
  (assert-equal (* 3 4) 12)))

(run-tests)  ;; prints summary, exits with 0/1
```

- `test` registers a named test (thunk). Does not run it immediately.
- `assert-equal` compares with `equal?`, reports expected vs actual on failure.
- `assert-true` checks truthiness.
- `assert-error` verifies that an expression signals an error (wraps `try-eval`).
- `run-tests` executes all registered tests, catches errors per-test, prints summary.

**Rationale:** Deferred execution via `run-tests` allows collecting all tests first, then running with proper error isolation. Each test thunk is wrapped in `try-eval` so one failure doesn't abort the suite.

### 3. Test files organized by category under `tests/ece/`

```
tests/
  ece/
    test-framework.scm      -- test framework
    test-arithmetic.scm      -- +, -, *, /, modulo, abs, min, max
    test-lists.scm           -- cons, car, cdr, map, filter, reduce, append, ...
    test-strings.scm         -- string ops, comparisons, interpolation
    test-vectors.scm         -- vector construction, access, mutation
    test-hash-tables.scm     -- hash table ops, literals, mutation
    test-control-flow.scm    -- if, cond, case, and, or, when, unless, do
    test-closures.scm        -- lambda, let, let*, letrec, named let, closures
    test-macros.scm          -- define-macro, quasiquote, macro shadowing
    test-tco.scm             -- tail call optimization across all forms
    test-callcc.scm          -- call/cc continuations
    test-types.scm           -- type predicates, equality, boolean ops
    test-higher-order.scm    -- map, filter, reduce, for-each, compose, any, every
    test-records.scm         -- define-record
    test-errors.scm          -- error signaling, assert
    test-parameters.scm      -- make-parameter, parameterize
    run-all.scm              -- loads framework + all test files, calls run-tests
```

**Rationale:** Category-based organization makes it easy to run subsets. `run-all.scm` is the single entry point. Placing under `tests/ece/` keeps ECE-native tests separate from the CL/rove tests at `tests/ece.lisp`.

### 4. `make test-ece` loads the image and runs the test suite

```makefile
test-ece:
	qlot exec sbcl --eval '(asdf:load-system :ece)' \
	  --eval '(ece:evaluate (list (quote load) "tests/ece/run-all.scm"))' \
	  --quit
```

On the CL host, this loads the ECE system (with image) and then evaluates `(load "tests/ece/run-all.scm")` in ECE. On a C or WASM host, the equivalent would just be loading and running `run-all.scm`.

**Rationale:** The Makefile target provides a one-command entry point. The actual test execution is pure ECE — the Makefile just bootstraps the runtime.

### 5. Exit code reflects test results

`run-tests` prints a summary line (`N passed, M failed`) and returns a boolean. The Makefile target translates this to a process exit code (0 for all pass, 1 for any failure) so CI can gate on it.

**Rationale:** Standard CI convention. The CL host uses `(sb-ext:exit :code 1)` or equivalent; other platforms would use their native exit mechanism.

## Risks / Trade-offs

- **Test coverage drift** — ECE tests and CL tests could diverge over time. Mitigation: document which CL tests have ECE equivalents; new pure-semantics tests should be added to both.
- **No test isolation** — Tests share the global env. A test that defines `x` could affect later tests. Mitigation: use descriptive names (test-prefixed) and avoid relying on prior state. Same pattern as the existing CL tests.
- **`try-eval` is a CL primitive** — The test framework depends on `try-eval` to catch errors per-test. This primitive must exist on every platform. Mitigation: `try-eval` is a minimal primitive (just error catching) — easy to implement on any platform.
