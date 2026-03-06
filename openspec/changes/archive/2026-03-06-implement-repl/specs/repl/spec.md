## ADDED Requirements

### Requirement: I/O primitives are available
The evaluator SHALL expose `read`, `print`, `display`, and `newline` as primitive procedures in the global environment.

#### Scenario: read is callable
- **WHEN** `read` is looked up in `*global-env*`
- **THEN** it SHALL resolve to a primitive that reads an s-expression from standard input with `*read-eval*` bound to `nil`

#### Scenario: print is callable
- **WHEN** evaluating `(print 42)`
- **THEN** it SHALL print `42` to standard output and return `42`

#### Scenario: display writes without leading newline
- **WHEN** evaluating `(display "hello")`
- **THEN** it SHALL write `hello` to standard output without a leading newline

#### Scenario: newline writes a newline
- **WHEN** evaluating `(newline)`
- **THEN** it SHALL write a newline character to standard output

### Requirement: REPL is implemented as an ECE function
The REPL loop SHALL be implemented as a tail-recursive ECE function defined with `define`, not as a CL-side loop.

#### Scenario: Basic REPL interaction
- **WHEN** the user types `(+ 1 2)` at the REPL prompt
- **THEN** the REPL SHALL print `3` and display a new prompt

#### Scenario: REPL handles evaluation errors
- **WHEN** the user types an expression that causes an error (e.g., unbound variable)
- **THEN** the REPL SHALL print the error message and continue with a new prompt (not crash)

#### Scenario: REPL exits on EOF
- **WHEN** the user sends EOF (Ctrl-D)
- **THEN** the REPL SHALL exit cleanly

### Requirement: REPL is launchable from the command line
The `ece:repl` CL function SHALL bootstrap the ECE REPL by evaluating the loop definition and starting it.

#### Scenario: Command-line launch
- **WHEN** running `qlot exec sbcl --load ece.asd --eval '(ece:repl)'`
- **THEN** the REPL SHALL start and display a prompt
