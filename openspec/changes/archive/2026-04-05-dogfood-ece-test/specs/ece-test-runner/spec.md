## ADDED Requirements

### Requirement: ece-test filters tests by name substring
`ece-test --filter PATTERN` SHALL run only tests whose name contains PATTERN as a substring. Matching is case-sensitive. Multiple `--filter` flags SHALL compose with OR semantics.

#### Scenario: Single filter matches subset
- **GIVEN** tests `"parses integer"`, `"parses list"`, `"evaluates add"` are registered
- **WHEN** `ece-test --filter parses tests/` is invoked
- **THEN** only `"parses integer"` and `"parses list"` SHALL run
- **AND** `"evaluates add"` SHALL NOT run

#### Scenario: Multiple filters OR together
- **GIVEN** tests `"parse-int"`, `"lex-char"`, `"eval-add"` are registered
- **WHEN** `ece-test --filter parse --filter lex tests/` is invoked
- **THEN** `"parse-int"` and `"lex-char"` SHALL run
- **AND** `"eval-add"` SHALL NOT run

#### Scenario: Filter that matches nothing
- **GIVEN** no test name contains `"nonexistent"`
- **WHEN** `ece-test --filter nonexistent tests/` is invoked
- **THEN** zero tests SHALL run
- **AND** the output SHALL report `0 ran`
- **AND** exit code SHALL be 0 (filter matched nothing is NOT a runner error)

#### Scenario: Empty filter matches everything
- **WHEN** `ece-test --filter "" tests/` is invoked
- **THEN** every registered test SHALL run

### Requirement: ece-test reports collected and ran counts
`ece-test` SHALL report four counts in its summary: `collected` (all tests registered across loaded files), `ran` (tests actually executed, i.e., collected minus filtered), `passed`, and `failed`.

#### Scenario: No filter, all tests run
- **GIVEN** 100 tests are registered
- **WHEN** `ece-test tests/` is invoked
- **THEN** the summary SHALL include `100 collected, 100 ran, 100 passed, 0 failed` (or equivalent ordering)

#### Scenario: Filter reduces ran count
- **GIVEN** 100 tests are registered and `--filter foo` matches 10
- **WHEN** `ece-test --filter foo tests/` is invoked
- **THEN** the summary SHALL include `100 collected, 10 ran`

## MODIFIED Requirements

### Requirement: ece-test exit codes reflect results
`ece-test` SHALL exit 0 if all tests pass, 1 if any test fails, and 2 if the runner itself errors (bad args, file not found, load error, or zero tests collected).

#### Scenario: All tests pass
- **WHEN** `ece-test` runs with all tests passing
- **THEN** exit code SHALL be 0

#### Scenario: At least one test fails
- **WHEN** `ece-test` runs with at least one failing test
- **THEN** exit code SHALL be 1

#### Scenario: Runner error — path does not exist
- **WHEN** `ece-test nonexistent/` is invoked and the directory does not exist
- **THEN** exit code SHALL be 2
- **AND** an error message SHALL be written to stderr

#### Scenario: Runner error — zero tests collected
- **GIVEN** a directory that contains no `test-*.scm` files
- **WHEN** `ece-test` is invoked against that directory
- **THEN** exit code SHALL be 2
- **AND** a message explaining zero tests collected SHALL be written to stderr

### Requirement: test-lib.scm provides the assertion API
`$ECE_HOME/ece-unit.scm` SHALL export at minimum: `test` (register a named test thunk), `assert-equal`, `assert-true`, `assert-false`, `assert-error`, `assert-error-message`, `run-tests`.

#### Scenario: Test registration
- **WHEN** a file loads `ece-unit` and calls `(test "name" (lambda () (assert-equal 1 1)))`
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
