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
