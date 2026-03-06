## ADDED Requirements

### Requirement: Arithmetic primitive / is tested
The test suite SHALL verify division via the evaluator.

#### Scenario: Simple division
- **WHEN** evaluating `(/ 10 2)`
- **THEN** the result SHALL be `5`

### Requirement: Comparison primitives are tested
The test suite SHALL verify `=`, `<`, `>`, `<=`, `>=` via the evaluator.

#### Scenario: Equality check
- **WHEN** evaluating `(= 3 3)`
- **THEN** the result SHALL be truthy

#### Scenario: Less than
- **WHEN** evaluating `(< 1 2)`
- **THEN** the result SHALL be truthy

#### Scenario: Greater than
- **WHEN** evaluating `(> 5 3)`
- **THEN** the result SHALL be truthy

#### Scenario: Less than or equal
- **WHEN** evaluating `(<= 3 3)`
- **THEN** the result SHALL be truthy

#### Scenario: Greater than or equal
- **WHEN** evaluating `(>= 4 3)`
- **THEN** the result SHALL be truthy

### Requirement: List primitives are tested
The test suite SHALL verify `car`, `cdr`, `cons`, `list`, `null?`, and `not` via the evaluator.

#### Scenario: cons creates a pair
- **WHEN** evaluating `(cons 1 2)`
- **THEN** the result SHALL be the pair `(1 . 2)`

#### Scenario: car returns first element
- **WHEN** evaluating `(car (cons 1 2))`
- **THEN** the result SHALL be `1`

#### Scenario: cdr returns second element
- **WHEN** evaluating `(cdr (cons 1 2))`
- **THEN** the result SHALL be `2`

#### Scenario: list creates a list
- **WHEN** evaluating `(list 1 2 3)`
- **THEN** the result SHALL be `(1 2 3)`

#### Scenario: null? on nil
- **WHEN** evaluating `(null? (quote ()))`
- **THEN** the result SHALL be truthy

#### Scenario: null? on non-nil
- **WHEN** evaluating `(null? (quote (1)))`
- **THEN** the result SHALL be falsy

#### Scenario: not on nil
- **WHEN** evaluating `(not (quote ()))`
- **THEN** the result SHALL be truthy
