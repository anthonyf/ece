## ADDED Requirements

### Requirement: string=? tests string equality
The evaluator SHALL provide `string=?` that returns true if two strings are equal.

#### Scenario: Equal strings
- **WHEN** evaluating `(string=? "hello" "hello")`
- **THEN** the result SHALL be true

#### Scenario: Unequal strings
- **WHEN** evaluating `(string=? "hello" "world")`
- **THEN** the result SHALL be false

### Requirement: string<? tests string ordering
The evaluator SHALL provide `string<?` that returns true if the first string is lexicographically less than the second.

#### Scenario: Less than
- **WHEN** evaluating `(string<? "abc" "abd")`
- **THEN** the result SHALL be true

#### Scenario: Not less than
- **WHEN** evaluating `(string<? "abd" "abc")`
- **THEN** the result SHALL be false

### Requirement: string>? tests string ordering
The evaluator SHALL provide `string>?` that returns true if the first string is lexicographically greater than the second.

#### Scenario: Greater than
- **WHEN** evaluating `(string>? "abd" "abc")`
- **THEN** the result SHALL be true

#### Scenario: Not greater than
- **WHEN** evaluating `(string>? "abc" "abd")`
- **THEN** the result SHALL be false
