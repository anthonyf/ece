## ADDED Requirements

### Requirement: list? tests for proper list
The evaluator SHALL provide `list?` that returns `#t` if the argument is a proper list (a chain of pairs terminated by the empty list), `#f` otherwise.

#### Scenario: Proper list
- **WHEN** evaluating `(list? '(1 2 3))`
- **THEN** the result SHALL be `#t`

#### Scenario: Empty list
- **WHEN** evaluating `(list? '())`
- **THEN** the result SHALL be `#t`

#### Scenario: Not a list
- **WHEN** evaluating `(list? 42)`
- **THEN** the result SHALL be `#f`

#### Scenario: Dotted pair
- **WHEN** evaluating `(list? '(1 . 2))`
- **THEN** the result SHALL be `#f`

#### Scenario: Nested list
- **WHEN** evaluating `(list? '(1 (2 3) 4))`
- **THEN** the result SHALL be `#t`

### Requirement: procedure? tests for callable objects
The evaluator SHALL provide `procedure?` that returns `#t` if the argument is a callable procedure (compiled procedure, primitive, or continuation), `#f` otherwise.

#### Scenario: Lambda is a procedure
- **WHEN** evaluating `(procedure? (lambda (x) x))`
- **THEN** the result SHALL be `#t`

#### Scenario: Primitive is a procedure
- **WHEN** evaluating `(procedure? car)`
- **THEN** the result SHALL be `#t`

#### Scenario: Continuation is a procedure
- **WHEN** evaluating `(call/cc (lambda (k) (procedure? k)))`
- **THEN** the result SHALL be `#t`

#### Scenario: Number is not a procedure
- **WHEN** evaluating `(procedure? 42)`
- **THEN** the result SHALL be `#f`

#### Scenario: String is not a procedure
- **WHEN** evaluating `(procedure? "hello")`
- **THEN** the result SHALL be `#f`

#### Scenario: List is not a procedure
- **WHEN** evaluating `(procedure? '(1 2 3))`
- **THEN** the result SHALL be `#f`
