## Context

ECE has 28 test files covering its own features but no external conformance validation. Published test suites exist: R5RS pitfall tests (~18 edge cases) and Chibi R5RS tests (~150 tests with a self-contained `syntax-rules`-based framework). ECE now has `syntax-rules` support, making it possible to run the Chibi tests which use `syntax-rules` to define their `test` macro.

ECE's existing test framework defines a `test` macro. The Chibi tests also define `test`. These must not collide.

## Goals / Non-Goals

**Goals:**
- Run published conformance tests to reveal spec gaps
- Keep external tests as close to upstream as possible for easy updates
- Isolate conformance tests from the ECE test suite (separate session, separate runner)
- Report pass/fail/skip clearly so gaps are actionable

**Non-Goals:**
- Achieving 100% pass rate immediately — failures are informational
- Chibi R7RS tests (deferred until R5RS gaps are addressed)
- Modifying ECE to pass failing tests (that's separate work driven by the results)
- Implementing SRFI-64 or other standard test frameworks

## Decisions

### 1. Self-contained runner in separate directory

Conformance tests live in `tests/conformance/` with their own runner (`run-conformance.scm`). They run in a separate SBCL invocation via `make test-conformance`, so their `test` macro doesn't collide with ECE's.

**Alternative considered:** Loading conformance tests within the existing test framework using a namespace prefix (`chibi-test`). Rejected because it forces modifications to upstream test files, making updates harder.

### 2. Minimal adaptation of upstream tests

For each test suite:
- **R5RS pitfall tests**: No framework. Wrap each test case in a minimal `(conformance-test name thunk)` call. Adapt from the published source at sisc-scheme.org / husk-scheme GitHub mirror.
- **Chibi R5RS tests**: Keep the file mostly verbatim. The inline `test` macro (defined via `syntax-rules` at the top of the file) works as-is. Adapt only: remove `(import ...)` if present, replace `call-with-output-string` and `flush-output` calls in the framework preamble with ECE equivalents or stubs.

### 3. Conformance runner reports but doesn't block

The runner tracks pass/fail/skip counts. `make test-conformance` prints results and exits with code 0 (informational). CI runs it with `continue-on-error: true`. A separate `make test-conformance-strict` target exits non-zero on failures, for use once gaps are closed.

**Alternative considered:** Blocking CI on conformance failures. Rejected because initial failures are expected and would block all PRs until fixed.

### 4. License compliance

- Chibi R5RS tests: BSD-3-Clause — safe to include with attribution
- R5RS pitfall tests: Copyright Scott G. Miller, no explicit license. Include as adapted tests with attribution rather than verbatim copy. If license is unclear, write equivalent tests inspired by the pitfall cases.

## Risks / Trade-offs

**[Tests may need ECE-specific adaptation]** → Some tests may use R5RS features ECE doesn't implement (e.g., `call-with-output-string`, `exact->inexact`). Mitigation: stub or skip tests that use unsupported features, document which features are missing.

**[Chibi test framework uses features we may not support]** → The Chibi `test` macro uses `call-with-output-string` for display. Mitigation: replace with simpler display logic or stub.

**[R5RS pitfall license unclear]** → Mitigation: write equivalent tests inspired by the pitfall cases rather than copying verbatim.
