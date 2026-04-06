## ADDED Requirements

### Requirement: Test registration
The framework SHALL provide a `test` form that registers a named test thunk without executing it immediately.

#### Scenario: Register a test
- **WHEN** `(test "my test" (lambda () (assert-true #t)))` is evaluated
- **THEN** the test is stored in the test registry with name `"my test"` and can be executed later by `run-tests`

### Requirement: assert-equal comparison
The framework SHALL provide `assert-equal` that compares two values using `equal?` and records a failure with expected vs actual on mismatch.

#### Scenario: Passing assertion
- **WHEN** `(assert-equal (+ 1 2) 3)` is evaluated
- **THEN** the assertion passes and the pass count increments

#### Scenario: Failing assertion
- **WHEN** `(assert-equal (+ 1 2) 4)` is evaluated
- **THEN** the assertion fails, the failure count increments, and the failure message includes expected `4` and actual `3`

### Requirement: assert-true check
The framework SHALL provide `assert-true` that checks a value is truthy (not `#f`).

#### Scenario: Truthy value passes
- **WHEN** `(assert-true (> 3 2))` is evaluated
- **THEN** the assertion passes

#### Scenario: False value fails
- **WHEN** `(assert-true (> 2 3))` is evaluated
- **THEN** the assertion fails with a message indicating the value was false

### Requirement: assert-error check
The framework SHALL provide `assert-error` that verifies an expression signals an error. It SHALL use `try-eval` to catch errors.

#### Scenario: Expression that errors passes
- **WHEN** `(assert-error (/ 1 0))` is evaluated
- **THEN** the assertion passes because the expression signaled an error

#### Scenario: Expression that succeeds fails
- **WHEN** `(assert-error (+ 1 2))` is evaluated
- **THEN** the assertion fails because no error was signaled

### Requirement: assert-error-message checks error message content
The framework SHALL provide `assert-error-message` that evaluates an expression, expects it to raise an error, and verifies the `error-object-message` matches the expected string.

#### Scenario: Matching error message passes
- **WHEN** `(assert-error-message (error "expected") "expected")` is evaluated
- **THEN** the assertion passes and the pass count increments

#### Scenario: Wrong error message fails
- **WHEN** an error is raised with message `"actual"` but expected was `"different"`
- **THEN** the assertion fails with a message showing expected vs actual error messages

#### Scenario: No error raised fails
- **WHEN** the expression succeeds without raising an error
- **THEN** the assertion fails indicating no error was raised when one was expected

#### Scenario: Non-error-object exception fails gracefully
- **WHEN** `(raise 42)` is evaluated but `assert-error-message` expected an error object
- **THEN** the assertion fails indicating the raised value was not an error object

### Requirement: Framework file location
The framework SHALL live in `src/ece-unit.scm` and be shipped to `$PREFIX/share/ece/ece-unit.scm` on install. A single file SHALL provide the entire assertion API and runner; no separate in-tree framework (e.g. `tests/ece/test-framework.scm`) SHALL be needed.

#### Scenario: User tests load the framework by name
- **WHEN** a user's test file runs under `ece-test`
- **THEN** `test`, `assert-equal`, `assert-true`, `assert-false`, `assert-error`, `assert-error-message`, and `run-tests` SHALL be available in the loaded environment without an explicit `(load ...)`

#### Scenario: ECE's own tests use the same framework
- **WHEN** files under `tests/ece/common/` or `tests/ece/cl-only/` are run via `ece-test`
- **THEN** they SHALL use the same `test`/`assert-*` API exported from `src/ece-unit.scm`
- **AND** no parallel framework file SHALL exist in the repository

### Requirement: run-tests returns a result tuple
`run-tests` SHALL return a tuple containing `collected`, `ran`, `passes`, `failures`, `failure-messages`, and `per-test-output`. It SHALL NOT print the summary itself; the caller (e.g. `ece-test`) is responsible for formatting output.

#### Scenario: All tests pass returns correct counts
- **GIVEN** 5 tests are registered and all pass
- **WHEN** `(run-tests)` is called
- **THEN** the returned tuple SHALL indicate 5 collected, 5 ran, 5 passes, 0 failures

#### Scenario: Filter reduces ran count
- **GIVEN** 10 tests are registered and a matcher that matches 3
- **WHEN** `(run-tests matcher)` is called
- **THEN** the returned tuple SHALL indicate 10 collected, 3 ran

### Requirement: Test execution with error isolation
`run-tests` SHALL execute all registered tests, wrapping each in a `guard` handler so that one test failure or error does not abort the suite. Unhandled errors SHALL be recorded as test failures with an explanatory message.

#### Scenario: One test errors, others continue
- **WHEN** three tests are registered and the second one signals an unhandled error
- **THEN** all three tests are executed, the second is marked as failed with an ERROR message, and the first and third run normally

### Requirement: Summary output
The caller of `run-tests` (e.g. the `ece-test` runner) SHALL format and print the summary from the returned tuple. The framework itself SHALL NOT print.

#### Scenario: Runner formats the summary
- **WHEN** `run-tests` returns `(5 5 5 0 () ())`
- **THEN** the runner SHALL print a human-readable summary that includes `5 passed, 0 failed`

### ~~Requirement: Exit status~~ (REMOVED)
**Removed**: `run-tests` no longer returns a boolean; it returns a counts tuple. Exit code mapping lives in the `ece-test` runner, not in the framework.

**Migration**: Callers that previously relied on `(if (run-tests) ok-action fail-action)` SHALL inspect the returned tuple's `failures` count: `(if (zero? (failures-of (run-tests))) ok fail)`. The `ece-test` binary already does this translation; user scripts need to update to the tuple shape.
