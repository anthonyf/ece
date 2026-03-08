## ADDED Requirements

### Requirement: clamp constrains a number to a range
`clamp` SHALL accept three arguments `(x low high)` and return `x` constrained to the range `[low, high]`.

#### Scenario: Value within range
- **WHEN** `(clamp 5 0 10)` is evaluated
- **THEN** the result SHALL be `5`

#### Scenario: Value below range
- **WHEN** `(clamp -3 0 10)` is evaluated
- **THEN** the result SHALL be `0`

#### Scenario: Value above range
- **WHEN** `(clamp 15 0 10)` is evaluated
- **THEN** the result SHALL be `10`

#### Scenario: Value at boundary
- **WHEN** `(clamp 0 0 10)` is evaluated
- **THEN** the result SHALL be `0`
