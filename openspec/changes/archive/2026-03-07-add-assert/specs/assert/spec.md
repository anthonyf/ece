## ADDED Requirements

### Requirement: assert signals error on falsy condition
`assert` SHALL signal an error when the condition expression evaluates to a falsy value (nil or `#f`).

#### Scenario: Falsy condition signals error
- **WHEN** `(assert #f)` is evaluated
- **THEN** an error SHALL be signaled with the message `"Assertion failed"`

#### Scenario: Truthy condition passes silently
- **WHEN** `(assert #t)` is evaluated
- **THEN** no error SHALL be signaled

#### Scenario: Non-boolean truthy values pass
- **WHEN** `(assert 42)` is evaluated
- **THEN** no error SHALL be signaled

### Requirement: assert accepts optional custom message
`assert` SHALL accept an optional second argument as a custom error message string.

#### Scenario: Custom message on failure
- **WHEN** `(assert #f "x must be positive")` is evaluated
- **THEN** an error SHALL be signaled with the message `"x must be positive"`

#### Scenario: Custom message not used on success
- **WHEN** `(assert #t "should not see this")` is evaluated
- **THEN** no error SHALL be signaled
