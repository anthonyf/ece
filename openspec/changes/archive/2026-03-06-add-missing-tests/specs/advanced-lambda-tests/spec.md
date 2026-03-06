## ADDED Requirements

### Requirement: Multi-body lambda returns last expression
The test suite SHALL verify that a lambda with multiple body expressions evaluates all and returns the last value.

#### Scenario: Two-expression body
- **WHEN** evaluating `((lambda (x) (+ x 1) (+ x 2)) 10)`
- **THEN** the result SHALL be `12`

### Requirement: Nested application is evaluated correctly
The test suite SHALL verify that nested function calls are resolved properly.

#### Scenario: Nested arithmetic
- **WHEN** evaluating `(+ (* 2 3) (- 10 4))`
- **THEN** the result SHALL be `12`

#### Scenario: Deeply nested
- **WHEN** evaluating `(+ (+ 1 2) (+ 3 (+ 4 5)))`
- **THEN** the result SHALL be `15`
