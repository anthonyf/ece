## ADDED Requirements

### Requirement: Begin evaluates sequence and returns last value
The test suite SHALL verify that `(begin ...)` evaluates all expressions in order and returns the value of the last expression.

#### Scenario: Single expression begin
- **WHEN** evaluating `(begin 42)`
- **THEN** the result SHALL be `42`

#### Scenario: Multiple expression begin
- **WHEN** evaluating `(begin 1 2 3)`
- **THEN** the result SHALL be `3`

#### Scenario: Begin with side-effecting expressions
- **WHEN** evaluating `(begin (+ 1 2) (* 3 4))`
- **THEN** the result SHALL be `12`
