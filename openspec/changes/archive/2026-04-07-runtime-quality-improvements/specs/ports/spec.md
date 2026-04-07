## ADDED Requirements

### Requirement: port mutator functions
The CL runtime SHALL provide mutator functions `set-ece-port-line!` and `set-ece-port-col!` for updating port tracking state. All internal code that mutates port line/column tracking SHALL use these mutators instead of raw `setf`/`cadddr` access.

#### Scenario: line tracking via mutator
- **WHEN** `ece-read-char` reads a newline character from a port
- **THEN** the port's line counter SHALL be incremented via `set-ece-port-line!`
- **AND** the port's column counter SHALL be reset to 0 via `set-ece-port-col!`

#### Scenario: column tracking via mutator
- **WHEN** `ece-read-char` reads a non-newline character from a port
- **THEN** the port's column counter SHALL be incremented via `set-ece-port-col!`
