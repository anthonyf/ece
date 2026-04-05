## ADDED Requirements

### Requirement: ece-test discovers and runs test files
`ece-test` with one or more directory arguments SHALL discover files matching `test-*.scm` in each directory (non-recursively by default), load each in a fresh environment, and run any registered tests.

#### Scenario: Discover and run tests in a directory
- **GIVEN** `tests/` contains `test-foo.scm` (one passing test) and `test-bar.scm` (one passing test)
- **WHEN** `ece-test tests/` is invoked
- **THEN** both files SHALL be loaded and their tests executed
- **AND** the summary SHALL report `2 passed, 0 failed`
- **AND** exit code SHALL be 0

#### Scenario: Non-test files are skipped
- **GIVEN** `tests/` contains `test-foo.scm` and `helpers.scm`
- **WHEN** `ece-test tests/` is invoked
- **THEN** only `test-foo.scm` SHALL be loaded

### Requirement: ece-test accepts explicit file arguments
`ece-test` with file arguments SHALL run exactly those files as test files (no discovery).

#### Scenario: Single file argument
- **WHEN** `ece-test tests/test-foo.scm` is invoked
- **THEN** only `tests/test-foo.scm` SHALL be loaded and its tests SHALL run

#### Scenario: Mixed file arguments
- **WHEN** `ece-test tests/test-foo.scm tests/test-bar.scm` is invoked
- **THEN** both files SHALL run in the given order

### Requirement: ece-test isolates each test file
Each test file SHALL be loaded in a fresh test-state context so that test registrations and pass/fail counters do not leak between files.

#### Scenario: Failure in one file does not affect another
- **GIVEN** `test-foo.scm` has a failing assertion and `test-bar.scm` has a passing assertion
- **WHEN** `ece-test` runs both
- **THEN** the summary SHALL report `1 passed, 1 failed`
- **AND** the failure SHALL be attributed to `test-foo.scm`

### Requirement: ece-test captures per-test output
During each test, `current-output-port` SHALL be rebound so that test output is captured. Captured output SHALL be printed only for failing tests (or always printed when verbose mode is enabled).

#### Scenario: Passing test output is suppressed
- **GIVEN** a passing test that calls `(display "debug info")`
- **WHEN** `ece-test` runs the test
- **THEN** `debug info` SHALL NOT appear in the runner's normal output

#### Scenario: Failing test output is shown
- **GIVEN** a failing test that calls `(display "context") (assert-equal 1 2)`
- **WHEN** `ece-test` runs the test
- **THEN** `context` SHALL appear in the failure report

#### Scenario: Verbose mode always prints output
- **GIVEN** a passing test that calls `(display "trace")`
- **WHEN** `ece-test --verbose` runs the test
- **THEN** `trace` SHALL appear in the runner's output

### Requirement: ece-test exit codes reflect results
`ece-test` SHALL exit 0 if all tests pass, 1 if any test fails, and 2 if the runner itself errors (bad args, file not found, load error).

#### Scenario: All tests pass
- **WHEN** `ece-test` runs with all tests passing
- **THEN** exit code SHALL be 0

#### Scenario: At least one test fails
- **WHEN** `ece-test` runs with at least one failing test
- **THEN** exit code SHALL be 1

#### Scenario: Runner error
- **WHEN** `ece-test nonexistent/` is invoked and the directory does not exist
- **THEN** exit code SHALL be 2
- **AND** an error message SHALL be written to stderr

### Requirement: ece-test reports failures with context
For each failed assertion, the report SHALL include the test name, the expected and actual values (for equality assertions), and any captured output from the test body.

#### Scenario: Equality failure shows expected and actual
- **GIVEN** a test named `"sum"` that calls `(assert-equal (+ 1 1) 3)`
- **WHEN** `ece-test` runs it
- **THEN** the failure report SHALL mention the test name `sum`
- **AND** SHALL include both `expected 3` and `actual 2` (or equivalent)

### Requirement: test-lib.scm provides the assertion API
`$ECE_HOME/test-lib.scm` SHALL export at minimum: `test` (register a named test thunk), `assert-equal`, `assert-true`, `assert-false`, `assert-error`, `assert-error-message`, `run-tests`.

#### Scenario: Test registration
- **WHEN** a file loads `test-lib` and calls `(test "name" (lambda () (assert-equal 1 1)))`
- **THEN** the test SHALL be registered and runnable by `(run-tests)`

#### Scenario: assert-equal passes on equal values
- **WHEN** `(assert-equal 42 42)` is evaluated inside a test
- **THEN** the test pass counter SHALL increment

#### Scenario: assert-equal fails on unequal values
- **WHEN** `(assert-equal 42 43)` is evaluated inside a test
- **THEN** the test fail counter SHALL increment
- **AND** a failure message SHALL be captured

#### Scenario: assert-error passes when body raises
- **WHEN** `(assert-error (raise 'boom))` is evaluated inside a test
- **THEN** the test pass counter SHALL increment

#### Scenario: assert-error fails when body does not raise
- **WHEN** `(assert-error 42)` is evaluated inside a test
- **THEN** the test fail counter SHALL increment
