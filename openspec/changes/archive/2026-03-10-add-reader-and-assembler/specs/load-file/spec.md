## MODIFIED Requirements

### Requirement: load reads and evaluates all expressions from a file
The evaluator SHALL provide `load` as a primitive that opens a file, reads all s-expressions using the ECE reader, and evaluates each one in sequence. The file SHALL be wrapped in an input port and read using the ECE reader in a loop until EOF.

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

#### Scenario: Load uses ECE reader
- **WHEN** a file is loaded after bootstrap
- **THEN** expressions SHALL be parsed by the ECE reader, not the CL reader
