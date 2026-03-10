## ADDED Requirements

### Requirement: REPL evaluates simple expressions
The REPL SHALL evaluate literal values and arithmetic expressions and print results.

#### Scenario: Integer literal
- **WHEN** the REPL receives input `42`
- **THEN** the output SHALL contain `42`

#### Scenario: Arithmetic expression
- **WHEN** the REPL receives input `(+ 1 2)`
- **THEN** the output SHALL contain `3`

### Requirement: REPL handles multiple expressions in a session
The REPL SHALL process multiple expressions sequentially, printing each result.

#### Scenario: Three expressions
- **WHEN** the REPL receives `1`, `2`, `3` on separate lines
- **THEN** the output SHALL contain all three results and multiple `ece> ` prompts

### Requirement: REPL handles variable definition
The REPL SHALL support defining variables and using them in subsequent expressions.

#### Scenario: Define and use variable
- **WHEN** the REPL receives `(define repl-test-x 10)` followed by `repl-test-x`
- **THEN** the output SHALL contain `10` as the result of the second expression

### Requirement: REPL handles function definition without crashing
The REPL SHALL print a function name (not crash) when a function is defined, and SHALL correctly call the defined function.

#### Scenario: Define and call function
- **WHEN** the REPL receives `(define (repl-test-plus a b) (+ a b))` followed by `(repl-test-plus 3 4)`
- **THEN** the output SHALL contain `REPL-TEST-PLUS` and `7`

### Requirement: REPL recovers from errors
The REPL SHALL print an error message and continue processing when an expression signals an error.

#### Scenario: Unbound variable error then recovery
- **WHEN** the REPL receives an unbound variable reference followed by a valid expression
- **THEN** the output SHALL contain `Error:` for the first expression and the correct result for the second

### Requirement: REPL prints strings in write format
The REPL SHALL print string results with quotes (write format).

#### Scenario: String literal
- **WHEN** the REPL receives a string literal `"hello"`
- **THEN** the output SHALL contain `"hello"` with surrounding quotes

### Requirement: REPL handles boolean values
The REPL SHALL print `T` for `#t`. For `#f` (nil), since the result is falsy, no value is printed.

#### Scenario: True value
- **WHEN** the REPL receives `#t`
- **THEN** the output SHALL contain `T`

#### Scenario: False value
- **WHEN** the REPL receives `#f`
- **THEN** the output SHALL NOT print a result value (nil is falsy, suppressed by REPL)

### Requirement: REPL prints lambda without crashing
The REPL SHALL print anonymous lambda procedures using a readable representation without triggering infinite recursion.

#### Scenario: Anonymous lambda
- **WHEN** the REPL receives `(lambda (x) x)`
- **THEN** the output SHALL contain `procedure` (not crash)

### Requirement: REPL prints goodbye on EOF
The REPL SHALL print `Bye!` when input is exhausted.

#### Scenario: EOF after expressions
- **WHEN** the REPL input is exhausted (EOF)
- **THEN** the output SHALL contain `Bye!`

### Requirement: REPL displays prompt
The REPL SHALL display `ece> ` as a prompt before reading each expression.

#### Scenario: Prompt appears
- **WHEN** the REPL starts and processes input
- **THEN** the output SHALL contain `ece> `
