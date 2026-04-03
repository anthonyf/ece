## MODIFIED Requirements

### Requirement: conformance runner tracks pass/fail/skip counts
The conformance test runner SHALL maintain counters for passed, failed, and skipped tests. After all tests complete, it SHALL print a summary line with counts.

#### Scenario: All tests pass
- **WHEN** running a conformance suite where all tests pass
- **THEN** the summary SHALL show the total passed count, 0 failed, and 0 skipped

#### Scenario: Mixed results
- **WHEN** running a conformance suite with some failures and skips
- **THEN** the summary SHALL show accurate counts for each category

### Requirement: Conformance failures block CI
The CI pipeline SHALL treat conformance test failures as build failures. The `continue-on-error: true` setting SHALL be removed from the conformance step in `.github/workflows/test.yml`.

#### Scenario: Conformance test fails in CI
- **WHEN** a conformance test fails during a CI run
- **THEN** the CI build SHALL fail and the PR SHALL NOT be mergeable

#### Scenario: All conformance tests pass in CI
- **WHEN** all conformance tests pass during a CI run
- **THEN** the CI build SHALL proceed to subsequent steps normally

#### Scenario: Known-failing test is skipped
- **WHEN** a test is marked with `conformance-skip!` because ECE does not yet implement the feature
- **THEN** the test SHALL be counted as skipped (not failed) and SHALL NOT cause CI failure
