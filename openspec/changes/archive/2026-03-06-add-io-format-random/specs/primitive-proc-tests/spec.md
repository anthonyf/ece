## ADDED Requirements

### Requirement: Bitwise primitives are tested
The test suite SHALL verify `bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, and `arithmetic-shift` via the evaluator.

#### Scenario: bitwise-and
- **WHEN** evaluating `(bitwise-and 12 10)`
- **THEN** the result SHALL be `8`

#### Scenario: bitwise-or
- **WHEN** evaluating `(bitwise-or 12 10)`
- **THEN** the result SHALL be `14`

#### Scenario: bitwise-xor
- **WHEN** evaluating `(bitwise-xor 12 10)`
- **THEN** the result SHALL be `6`

#### Scenario: bitwise-not
- **WHEN** evaluating `(bitwise-not 0)`
- **THEN** the result SHALL be `-1`

#### Scenario: arithmetic-shift left
- **WHEN** evaluating `(arithmetic-shift 1 8)`
- **THEN** the result SHALL be `256`

#### Scenario: arithmetic-shift right
- **WHEN** evaluating `(arithmetic-shift 256 -4)`
- **THEN** the result SHALL be `16`
