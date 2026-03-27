## ADDED Requirements

### Requirement: conformance runner tracks pass/fail/skip counts
The conformance test runner SHALL maintain counters for passed, failed, and skipped tests. After all tests complete, it SHALL print a summary line with counts.

#### Scenario: All tests pass
- **WHEN** running a conformance suite where all tests pass
- **THEN** the summary SHALL show the total passed count, 0 failed, and 0 skipped

#### Scenario: Mixed results
- **WHEN** running a conformance suite with some failures and skips
- **THEN** the summary SHALL show accurate counts for each category

### Requirement: conformance runner prints test name and status
Each test SHALL print its name and result (PASS, FAIL, or SKIP) as it runs, so failures are identifiable.

#### Scenario: Failing test shows expected vs actual
- **WHEN** a conformance test fails
- **THEN** the runner SHALL print the test name, the expected value, and the actual value

#### Scenario: Skipped test shows reason
- **WHEN** a conformance test is skipped
- **THEN** the runner SHALL print the test name and "SKIP"

### Requirement: conformance tests run in isolation from ECE tests
Conformance tests SHALL run in a separate SBCL session from the ECE test suite, so macro definitions (e.g., `test`) do not collide.

#### Scenario: make test-conformance runs independently
- **WHEN** running `make test-conformance`
- **THEN** the conformance tests SHALL execute without loading the ECE test framework

### Requirement: conformance runner supports skipping unsupported features
The runner SHALL provide a mechanism to skip tests that use features ECE does not yet implement, so the suite can run without modification to individual test expressions.

#### Scenario: Skipping a test by name
- **WHEN** a test is registered as skipped
- **THEN** it SHALL be counted as skipped (not failed) and not evaluated
