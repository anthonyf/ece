## MODIFIED Requirements

### Requirement: string->number parses a number from a string
The evaluator SHALL provide `string->number` that converts a string to a number using a dedicated parser (not the CL reader), or returns false if the string is not a valid number. Valid numbers are integers and decimal floats.

#### Scenario: Parse integer
- **WHEN** evaluating `(string->number "42")`
- **THEN** the result SHALL be `42`

#### Scenario: Parse negative number
- **WHEN** evaluating `(string->number "-7")`
- **THEN** the result SHALL be `-7`

#### Scenario: Parse float
- **WHEN** evaluating `(string->number "3.14")`
- **THEN** the result SHALL be `3.14`

#### Scenario: Parse negative float
- **WHEN** evaluating `(string->number "-0.5")`
- **THEN** the result SHALL be `-0.5`

#### Scenario: Invalid number returns false
- **WHEN** evaluating `(string->number "abc")`
- **THEN** the result SHALL be false

#### Scenario: Ratio syntax rejected
- **WHEN** evaluating `(string->number "3/4")`
- **THEN** the result SHALL be false

#### Scenario: Empty string returns false
- **WHEN** evaluating `(string->number "")`
- **THEN** the result SHALL be false

#### Scenario: Whitespace-only returns false
- **WHEN** evaluating `(string->number "  ")`
- **THEN** the result SHALL be false
