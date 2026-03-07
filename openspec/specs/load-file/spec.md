## ADDED Requirements

### Requirement: load reads and evaluates all expressions from a file
The evaluator SHALL provide `load` as a primitive that opens a file, reads all s-expressions, and evaluates each one in sequence.

#### Scenario: Load a file with definitions
- **WHEN** a file contains `(define x 42)` and `(define y (+ x 1))`
- **AND** evaluating `(load "<filename>")`
- **THEN** `x` SHALL be `42` and `y` SHALL be `43` in the global environment

#### Scenario: Load returns last value
- **WHEN** a file contains `(+ 1 2)` as its last expression
- **AND** evaluating `(load "<filename>")`
- **THEN** the result SHALL be `3`

#### Scenario: Load empty file
- **WHEN** a file is empty
- **AND** evaluating `(load "<filename>")`
- **THEN** the result SHALL be nil

#### Scenario: Load propagates errors
- **WHEN** a file contains an expression that signals an error
- **THEN** the error SHALL propagate to the caller (fail-fast)
