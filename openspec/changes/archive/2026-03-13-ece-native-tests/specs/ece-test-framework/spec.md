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

### Requirement: Test execution with error isolation
`run-tests` SHALL execute all registered tests, wrapping each in `try-eval` so that one test failure or error does not abort the suite.

#### Scenario: One test errors, others continue
- **WHEN** three tests are registered and the second one signals an unhandled error
- **THEN** all three tests are executed, the second is marked as failed/errored, and the first and third run normally

### Requirement: Summary output
`run-tests` SHALL print a summary line showing the count of passed and failed tests.

#### Scenario: All tests pass
- **WHEN** `run-tests` is called and all 5 registered tests pass
- **THEN** output includes `5 passed, 0 failed`

#### Scenario: Some tests fail
- **WHEN** `run-tests` is called and 3 pass while 2 fail
- **THEN** output includes `3 passed, 2 failed`

### Requirement: Exit status
`run-tests` SHALL return `#t` if all tests passed and `#f` if any test failed, enabling the host to translate this to a process exit code.

#### Scenario: All pass returns true
- **WHEN** all registered tests pass
- **THEN** `run-tests` returns `#t`

#### Scenario: Any failure returns false
- **WHEN** one or more tests fail
- **THEN** `run-tests` returns `#f`
