## ADDED Requirements

### Requirement: sleep pauses execution
The `sleep` function SHALL accept a numeric argument (integer or float) and pause execution for that many seconds. It SHALL return nil.

#### Scenario: Sleep for integer seconds
- **WHEN** `(sleep 1)` is evaluated
- **THEN** execution SHALL pause for approximately 1 second and return `()`

#### Scenario: Sleep for fractional seconds
- **WHEN** `(sleep 0.1)` is evaluated
- **THEN** execution SHALL pause for approximately 0.1 seconds and return `()`
