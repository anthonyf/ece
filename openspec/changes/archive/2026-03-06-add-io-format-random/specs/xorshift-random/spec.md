## ADDED Requirements

### Requirement: random returns a non-negative integer less than n
The evaluator SHALL provide `random` as a function that returns a pseudorandom non-negative integer less than its argument.

#### Scenario: Random is within range
- **WHEN** evaluating `(random 6)` repeatedly
- **THEN** the result SHALL always be between `0` and `5` inclusive

#### Scenario: Random with small range
- **WHEN** evaluating `(random 1)`
- **THEN** the result SHALL be `0`

### Requirement: random-seed! sets the PRNG seed
The evaluator SHALL provide `random-seed!` to set the PRNG state for reproducible sequences.

#### Scenario: Same seed produces same sequence
- **WHEN** evaluating `(random-seed! 42)` then `(random 100)` three times
- **AND** evaluating `(random-seed! 42)` then `(random 100)` three times again
- **THEN** both sequences SHALL be identical

### Requirement: *random-state* holds the current PRNG state
The evaluator SHALL provide `*random-state*` as a global variable holding the current PRNG state as a number.

#### Scenario: random-state is a number
- **WHEN** evaluating `*random-state*`
- **THEN** the result SHALL be a number

#### Scenario: random-state changes after random call
- **WHEN** evaluating `*random-state*` before and after `(random 10)`
- **THEN** the values SHALL be different
