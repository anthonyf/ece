## ADDED Requirements

### Requirement: trace enables entry/exit logging for a procedure
`(trace <name>)` SHALL enable tracing for the named procedure. Each subsequent call to the procedure SHALL print an entry line showing the procedure name and arguments, execute the original procedure, then print an exit line showing the return value.

#### Scenario: Trace a compiled procedure
- **WHEN** `(define (f x) (+ x 1))` is defined, then `(trace f)` is called, then `(f 5)` is called
- **THEN** output SHALL include an entry line containing `f` and `5`, and an exit line containing the return value `6`

#### Scenario: Trace a primitive procedure
- **WHEN** `(trace +)` is called, then `(+ 2 3)` is called
- **THEN** output SHALL include an entry line containing `+`, `2`, and `3`, and an exit line containing `5`

#### Scenario: Traced procedure returns correct value
- **WHEN** a procedure is traced and called
- **THEN** the return value SHALL be identical to calling the procedure without tracing

### Requirement: untrace restores original procedure
`(untrace <name>)` SHALL disable tracing and restore the original procedure binding.

#### Scenario: Untrace restores original behavior
- **WHEN** `(trace f)` is called, then `(untrace f)` is called, then `(f 5)` is called
- **THEN** no trace output SHALL be produced, and the return value SHALL be correct

#### Scenario: Untrace a non-traced procedure is a no-op
- **WHEN** `(untrace f)` is called on a procedure that is not currently traced
- **THEN** no error SHALL be raised

### Requirement: nested calls display with depth indentation
Traced calls SHALL be indented proportionally to call depth, making nested call structure visually clear.

#### Scenario: Nested traced calls show indentation
- **WHEN** `(define (f x) (g x))` and `(define (g x) (+ x 1))` are defined, both are traced, and `(f 5)` is called
- **THEN** the entry/exit lines for `g` SHALL be indented deeper than those for `f`

### Requirement: execute-compiled-call re-enters executor for compiled procedures
`execute-compiled-call` SHALL call a compiled procedure by re-entering `execute-instructions` with the proc and argl registers pre-loaded.

#### Scenario: Compiled procedure called via execute-compiled-call
- **WHEN** `execute-compiled-call` is called with a compiled procedure and argument list
- **THEN** it SHALL return the same value as calling the procedure through normal compiled dispatch

### Requirement: trace and untrace are available as primitives
`trace` and `untrace` SHALL be registered as primitives in the global environment, callable from ECE code.

#### Scenario: trace is callable from ECE
- **WHEN** `(trace f)` is evaluated in the ECE REPL
- **THEN** tracing SHALL be enabled for `f`

#### Scenario: untrace is callable from ECE
- **WHEN** `(untrace f)` is evaluated in the ECE REPL
- **THEN** tracing SHALL be disabled for `f`
