## Why

ECE has no way to verify conformance to R5RS/R7RS standards. Published Scheme test suites exist (Chibi R5RS, R5RS pitfall tests) that would reveal spec-conformance gaps and catch regressions. Now that `syntax-rules` is implemented, we can run test suites that use it as their framework.

## What Changes

- Add `tests/conformance/` directory with self-contained test runner, separate from the ECE test suite
- Integrate R5RS pitfall tests (~18 edge-case tests covering continuations, dynamic-wind, hygiene, tail calls)
- Integrate Chibi R5RS tests (~150 tests covering core R5RS features, self-contained syntax-rules framework)
- Add `make test-conformance` target that runs conformance tests in a separate SBCL session
- Add CI step for conformance tests (informational, `continue-on-error: true` — failures show gaps, not regressions)

## Capabilities

### New Capabilities
- `conformance-test-runner`: Self-contained test runner for external Scheme conformance suites, with pass/fail/skip reporting and exit code based on failure count

### Modified Capabilities

_(none)_

## Impact

- **New files**: `tests/conformance/` directory with runner, adapted test files, and any compatibility shims
- **Makefile**: New `test-conformance` target
- **CI**: New workflow step (non-blocking)
- **No impact** on existing ECE source, tests, or bootstrap
