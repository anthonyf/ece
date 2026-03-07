### Requirement: bitwise-and performs bitwise AND
The evaluator SHALL provide `bitwise-and` as a primitive.

#### Scenario: AND of two integers
- **WHEN** evaluating `(bitwise-and 12 10)`
- **THEN** the result SHALL be `8`

#### Scenario: AND with zero
- **WHEN** evaluating `(bitwise-and 255 0)`
- **THEN** the result SHALL be `0`

### Requirement: bitwise-or performs bitwise OR
The evaluator SHALL provide `bitwise-or` as a primitive.

#### Scenario: OR of two integers
- **WHEN** evaluating `(bitwise-or 12 10)`
- **THEN** the result SHALL be `14`

#### Scenario: OR with zero
- **WHEN** evaluating `(bitwise-or 0 5)`
- **THEN** the result SHALL be `5`

### Requirement: bitwise-xor performs bitwise XOR
The evaluator SHALL provide `bitwise-xor` as a primitive.

#### Scenario: XOR of two integers
- **WHEN** evaluating `(bitwise-xor 12 10)`
- **THEN** the result SHALL be `6`

#### Scenario: XOR with self is zero
- **WHEN** evaluating `(bitwise-xor 42 42)`
- **THEN** the result SHALL be `0`

### Requirement: bitwise-not performs bitwise NOT
The evaluator SHALL provide `bitwise-not` as a primitive.

#### Scenario: NOT of zero
- **WHEN** evaluating `(bitwise-not 0)`
- **THEN** the result SHALL be `-1`

#### Scenario: NOT of positive
- **WHEN** evaluating `(bitwise-not 255)`
- **THEN** the result SHALL be `-256`

### Requirement: arithmetic-shift performs bitwise shift
The evaluator SHALL provide `arithmetic-shift` as a primitive. Positive shift amounts shift left, negative shift amounts shift right.

#### Scenario: Left shift
- **WHEN** evaluating `(arithmetic-shift 1 8)`
- **THEN** the result SHALL be `256`

#### Scenario: Right shift
- **WHEN** evaluating `(arithmetic-shift 256 -4)`
- **THEN** the result SHALL be `16`

#### Scenario: Shift by zero
- **WHEN** evaluating `(arithmetic-shift 42 0)`
- **THEN** the result SHALL be `42`
