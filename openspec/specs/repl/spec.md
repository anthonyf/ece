## MODIFIED Requirements

### Requirement: I/O primitives are available
The evaluator SHALL expose `read`, `print`, `display`, and `newline` as primitive procedures in the global environment. After bootstrap, `read` SHALL use the ECE reader (reading from `current-input-port`) instead of CL's `read`.

#### Scenario: read is callable
- **WHEN** `read` is looked up in `*global-env*`
- **THEN** it SHALL resolve to a primitive that reads an s-expression from current-input-port

#### Scenario: read uses ECE reader after bootstrap
- **WHEN** `(read (open-input-string "(+ 1 2)"))` is called after bootstrap
- **THEN** it SHALL parse the expression using the ECE reader and return `(+ 1 2)`

#### Scenario: print is callable
- **WHEN** evaluating `(print 42)`
- **THEN** it SHALL print `42` to standard output and return `42`

#### Scenario: display writes without leading newline
- **WHEN** evaluating `(display "hello")`
- **THEN** it SHALL write `hello` to standard output without a leading newline

#### Scenario: newline writes a newline
- **WHEN** evaluating `(newline)`
- **THEN** it SHALL write a newline character to standard output

## ADDED Requirements

### Requirement: REPL supports Geiser mode via --geiser flag

The `bin/ece-repl` binary SHALL accept a `--geiser` command-line flag that switches the REPL's output formatting from free-form `write` to the structured alist response format the `geiser-backend` capability defines. When the flag is absent, the REPL's behavior is byte-identical to the pre-change REPL.

#### Scenario: Flag switches output format

- **WHEN** user runs `bin/ece-repl --geiser` and sends `(+ 1 2)` to stdin
- **THEN** the REPL SHALL emit a structured response recognizable by the Geiser elisp side, not a bare `3` on its own line

#### Scenario: Flag omitted preserves existing behavior

- **WHEN** user runs `bin/ece-repl` without `--geiser` and sends `(+ 1 2)` to stdin
- **THEN** the REPL SHALL print `3` followed by a newline, unchanged from pre-change behavior

#### Scenario: Unknown flag produces a usage error

- **WHEN** user runs `bin/ece-repl --bogus-flag`
- **THEN** the REPL SHALL print a usage error and exit with a nonzero status

### Requirement: REPL defined in ECE
The `repl` function SHALL be defined in `ece-main.scm` as an ECE function callable from compiled bytecode. When an expression raises an error during compilation or execution, the REPL SHALL recover such that subsequent expressions evaluate normally — error recovery SHALL NOT leave stale compilation state (labels, instruction-vector entries) in shared spaces that could affect later expressions.

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

#### Scenario: REPL error recovery leaves no stale state
- **WHEN** user types an expression that fails to compile, followed by a second, unrelated expression
- **THEN** the second expression SHALL compile and evaluate normally
- **AND** the system SHALL NOT raise "Unknown label" or any other error caused by state left behind by the first failed expression

#### Scenario: REPL exits on EOF
- **WHEN** user sends EOF (Ctrl-D)
- **THEN** the system prints `Bye!` and exits
