## ADDED Requirements

### Requirement: list-ref returns the element at an index
The evaluator SHALL provide `list-ref` that returns the element at a zero-based index in a list.

#### Scenario: First element
- **WHEN** evaluating `(list-ref '(a b c d) 0)`
- **THEN** the result SHALL be `a`

#### Scenario: Third element
- **WHEN** evaluating `(list-ref '(a b c d) 2)`
- **THEN** the result SHALL be `c`

#### Scenario: Last element
- **WHEN** evaluating `(list-ref '(a b c d) 3)`
- **THEN** the result SHALL be `d`

### Requirement: list-tail returns the sublist from an index
The evaluator SHALL provide `list-tail` that returns the sublist starting at a zero-based index.

#### Scenario: Tail from index 0
- **WHEN** evaluating `(list-tail '(a b c d) 0)`
- **THEN** the result SHALL be `(a b c d)`

#### Scenario: Tail from index 2
- **WHEN** evaluating `(list-tail '(a b c d) 2)`
- **THEN** the result SHALL be `(c d)`

#### Scenario: Tail at end
- **WHEN** evaluating `(list-tail '(a b c d) 4)`
- **THEN** the result SHALL be `()`
