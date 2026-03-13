## ADDED Requirements

### Requirement: Type error messages are testable
The test suite SHALL verify that type errors produce error objects with descriptive messages.

#### Scenario: Arithmetic type error
- **WHEN** `(+ "a" 1)` is evaluated inside a `guard`
- **THEN** an error object SHALL be caught and `error-object?` SHALL return `#t`

#### Scenario: car on non-pair
- **WHEN** `(car 5)` is evaluated inside a `guard`
- **THEN** an error object SHALL be caught

### Requirement: Unbound variable error messages
The test suite SHALL verify that referencing an unbound variable produces an error with the variable name in the message.

#### Scenario: Unbound variable error message content
- **WHEN** an unbound variable `nonexistent-var` is referenced inside a `guard`
- **THEN** the error message SHALL contain the string `"nonexistent-var"` or the symbol name

### Requirement: Division by zero error
The test suite SHALL verify that division by zero produces a catchable error.

#### Scenario: Division by zero caught by guard
- **WHEN** `(guard (e (#t e)) (/ 1 0))` is evaluated
- **THEN** an error SHALL be caught (not a crash)

### Requirement: Custom error messages via error
The test suite SHALL verify that `(error msg irritant ...)` produces inspectable error objects.

#### Scenario: Custom error message
- **WHEN** `(guard (e (#t (error-object-message e))) (error "custom problem"))` is evaluated
- **THEN** the result SHALL be `"custom problem"`

#### Scenario: Custom error with irritants
- **WHEN** `(guard (e (#t (error-object-irritants e))) (error "out of range" 42))` is evaluated
- **THEN** the result SHALL be `(42)`

### Requirement: assert-error-message tests error content
The test framework SHALL provide `assert-error-message` that verifies both that an error occurs and that the error message matches an expected string.

#### Scenario: Matching error message passes
- **WHEN** `(assert-error-message (error "expected msg") "expected msg")` is evaluated
- **THEN** the assertion passes

#### Scenario: Wrong error message fails
- **WHEN** an error is raised with message "actual" but expected message is "different"
- **THEN** the assertion fails with a message showing expected vs actual

#### Scenario: No error raised fails
- **WHEN** the expression does not raise an error but `assert-error-message` expected one
- **THEN** the assertion fails indicating no error was raised
