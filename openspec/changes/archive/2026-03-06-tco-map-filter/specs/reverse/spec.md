## ADDED Requirements

### Requirement: reverse returns a list in reverse order
The evaluator SHALL provide `reverse` as a primitive procedure that takes a list and returns a new list with elements in reverse order.

#### Scenario: Reverse a list
- **WHEN** evaluating `(reverse (quote (1 2 3)))`
- **THEN** the result SHALL be `(3 2 1)`

#### Scenario: Reverse empty list
- **WHEN** evaluating `(reverse (quote ()))`
- **THEN** the result SHALL be `()`

#### Scenario: Reverse single element
- **WHEN** evaluating `(reverse (quote (42)))`
- **THEN** the result SHALL be `(42)`
