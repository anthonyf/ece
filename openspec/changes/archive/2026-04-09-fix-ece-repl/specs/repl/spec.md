## ADDED Requirements

### Requirement: REPL defined in ECE
The `repl` function SHALL be defined in `ece-main.scm` as an ECE function callable from compiled bytecode.

#### Scenario: ece binary starts REPL
- **WHEN** user runs `ece` with no arguments
- **THEN** the system displays `ece> ` prompt and accepts input

#### Scenario: ece-repl binary starts REPL
- **WHEN** user runs `ece-repl`
- **THEN** the system displays `ece> ` prompt and accepts input

#### Scenario: REPL eval-print cycle
- **WHEN** user types `(+ 1 2)` at the REPL prompt
- **THEN** the system prints `3` and displays the next prompt

#### Scenario: REPL handles errors
- **WHEN** user types an expression that causes an error
- **THEN** the system prints the error message and displays the next prompt (does not crash)

#### Scenario: REPL exits on EOF
- **WHEN** user sends EOF (Ctrl-D)
- **THEN** the system prints `Bye!` and exits
