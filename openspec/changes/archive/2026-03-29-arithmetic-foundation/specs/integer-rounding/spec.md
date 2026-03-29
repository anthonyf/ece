## ADDED Requirements

### Requirement: truncate core primitive
The `truncate` primitive (ID 108) SHALL be implemented in both CL and WASM runtimes. It SHALL accept a number and return the integer closest to zero. For integers, it SHALL return the input unchanged. For floats (and CL rationals), it SHALL truncate toward zero.

#### Scenario: truncate positive float
- **WHEN** `(truncate 3.7)` is evaluated
- **THEN** the result SHALL be `3`

#### Scenario: truncate negative float
- **WHEN** `(truncate -3.7)` is evaluated
- **THEN** the result SHALL be `-3`

#### Scenario: truncate integer identity
- **WHEN** `(truncate 5)` is evaluated
- **THEN** the result SHALL be `5`

### Requirement: floor core primitive
The `floor` primitive (ID 109) SHALL be implemented in both CL and WASM runtimes. It SHALL accept a number and return the largest integer not greater than the input. For integers, it SHALL return the input unchanged.

#### Scenario: floor positive float
- **WHEN** `(floor 3.7)` is evaluated
- **THEN** the result SHALL be `3`

#### Scenario: floor negative float
- **WHEN** `(floor -3.7)` is evaluated
- **THEN** the result SHALL be `-4`

#### Scenario: floor integer identity
- **WHEN** `(floor 5)` is evaluated
- **THEN** the result SHALL be `5`

### Requirement: quotient derived in ECE
`quotient` SHALL be implemented in prelude.scm as `(truncate (/ a b))`. It SHALL perform truncation division (toward zero) per R7RS.

#### Scenario: positive quotient
- **WHEN** `(quotient 13 4)` is evaluated
- **THEN** the result SHALL be `3`

#### Scenario: negative dividend
- **WHEN** `(quotient -13 4)` is evaluated
- **THEN** the result SHALL be `-3`

#### Scenario: negative divisor
- **WHEN** `(quotient 13 -4)` is evaluated
- **THEN** the result SHALL be `-3`

#### Scenario: both negative
- **WHEN** `(quotient -13 -4)` is evaluated
- **THEN** the result SHALL be `3`

### Requirement: remainder derived in ECE
`remainder` SHALL be implemented in prelude.scm as `(- a (* (quotient a b) b))`. The sign of the result SHALL follow the sign of the dividend per R7RS.

#### Scenario: positive remainder
- **WHEN** `(remainder 13 4)` is evaluated
- **THEN** the result SHALL be `1`

#### Scenario: negative dividend remainder
- **WHEN** `(remainder -13 4)` is evaluated
- **THEN** the result SHALL be `-1`

#### Scenario: quotient-remainder identity
- **WHEN** `(+ (* (quotient a b) b) (remainder a b))` is evaluated for any integers `a`, `b` where `b` is non-zero
- **THEN** the result SHALL equal `a`

### Requirement: modulo derived in ECE
`modulo` SHALL be implemented in prelude.scm as `(- a (* (floor (/ a b)) b))`. The sign of the result SHALL follow the sign of the divisor per R7RS. This replaces the host primitive (ID 4).

#### Scenario: positive modulo
- **WHEN** `(modulo 13 4)` is evaluated
- **THEN** the result SHALL be `1`

#### Scenario: negative dividend modulo
- **WHEN** `(modulo -13 4)` is evaluated
- **THEN** the result SHALL be `3`

#### Scenario: negative divisor modulo
- **WHEN** `(modulo 13 -4)` is evaluated
- **THEN** the result SHALL be `-3`

#### Scenario: both negative modulo
- **WHEN** `(modulo -13 -4)` is evaluated
- **THEN** the result SHALL be `-1`

#### Scenario: modulo zero dividend
- **WHEN** `(modulo 0 5)` is evaluated
- **THEN** the result SHALL be `0`

#### Scenario: modulo division by zero
- **WHEN** `(modulo 10 0)` is evaluated
- **THEN** an error SHALL be signaled (from the underlying `/`)

### Requirement: ceiling derived in ECE
`ceiling` SHALL be implemented in prelude.scm. It SHALL return the smallest integer not less than the input.

#### Scenario: ceiling positive float
- **WHEN** `(ceiling 3.2)` is evaluated
- **THEN** the result SHALL be `4`

#### Scenario: ceiling negative float
- **WHEN** `(ceiling -3.7)` is evaluated
- **THEN** the result SHALL be `-3`

#### Scenario: ceiling integer identity
- **WHEN** `(ceiling 5)` is evaluated
- **THEN** the result SHALL be `5`

### Requirement: round derived in ECE
`round` SHALL be implemented in prelude.scm. It SHALL round to the nearest integer. When the input is exactly halfway between two integers, it SHALL round to the nearest even integer (banker's rounding) per R7RS.

#### Scenario: round down
- **WHEN** `(round 3.2)` is evaluated
- **THEN** the result SHALL be `3`

#### Scenario: round up
- **WHEN** `(round 3.7)` is evaluated
- **THEN** the result SHALL be `4`

#### Scenario: banker's rounding tie to even (even floor)
- **WHEN** `(round 4.5)` is evaluated
- **THEN** the result SHALL be `4`

#### Scenario: banker's rounding tie to even (odd floor)
- **WHEN** `(round 3.5)` is evaluated
- **THEN** the result SHALL be `4`

#### Scenario: round negative
- **WHEN** `(round -3.7)` is evaluated
- **THEN** the result SHALL be `-4`

### Requirement: boot ordering in prelude.scm
`quotient`, `remainder`, and `modulo` SHALL be defined in prelude.scm BEFORE the derived predicates section (before `even?`). `ceiling` and `round` SHALL be defined AFTER `even?` since `round` depends on it for banker's rounding.

#### Scenario: even? uses ECE modulo
- **WHEN** `(even? -7)` is evaluated after boot
- **THEN** the result SHALL be `#f`, using the ECE-derived `modulo` (not host primitive 4)
