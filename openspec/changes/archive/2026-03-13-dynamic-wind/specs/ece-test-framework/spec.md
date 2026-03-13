## ADDED Requirements

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
