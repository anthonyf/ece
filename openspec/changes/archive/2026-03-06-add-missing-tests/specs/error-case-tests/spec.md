## ADDED Requirements

### Requirement: Unknown expression type signals error
The test suite SHALL verify that the evaluator signals an error for unrecognized expression types.

#### Scenario: Non-list non-symbol non-number expression
- **WHEN** evaluating an expression the evaluator cannot classify (e.g., a hash table)
- **THEN** an error SHALL be signaled

### Requirement: Zero-argument function application works
The test suite SHALL verify that calling a function with no arguments works correctly.

#### Scenario: List with no arguments
- **WHEN** evaluating `(list)`
- **THEN** the result SHALL be `nil`
