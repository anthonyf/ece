## ADDED Requirements

### Requirement: Strings self-evaluate
The test suite SHALL verify that string literals evaluate to themselves.

#### Scenario: Simple string
- **WHEN** evaluating `"hello"`
- **THEN** the result SHALL be `"hello"`

#### Scenario: Empty string
- **WHEN** evaluating `""`
- **THEN** the result SHALL be `""`
