### Requirement: eval-string evaluates all expressions from a string
`eval-string` SHALL accept a string argument, open it as an input port, read all expressions using ECE's reader, and evaluate each expression in order using `eval`.

#### Scenario: Multiple expressions evaluated for side effects
- **WHEN** `(eval-string "(define x 10) (define y 20)")` is called
- **THEN** both `x` and `y` are defined in the current environment with values 10 and 20

#### Scenario: Empty string
- **WHEN** `(eval-string "")` is called
- **THEN** no expressions are evaluated and no error occurs

#### Scenario: String with only comments and whitespace
- **WHEN** `(eval-string ";; just a comment\n")` is called
- **THEN** no expressions are evaluated and no error occurs

#### Scenario: Reader error in source
- **WHEN** `(eval-string "(define x")` is called (unterminated list)
- **THEN** an error is signaled from ECE's reader

### Requirement: eval-string-last returns the last expression's value
`eval-string-last` SHALL accept a string argument, evaluate all expressions (like `eval-string`), and return the value of the last expression evaluated.

#### Scenario: Single expression returns its value
- **WHEN** `(eval-string-last "(+ 1 2)")` is called
- **THEN** the return value is `3`

#### Scenario: Multiple expressions returns last value
- **WHEN** `(eval-string-last "(define x 10) (+ x 5)")` is called
- **THEN** `x` is defined and the return value is `15`

#### Scenario: Empty string returns void
- **WHEN** `(eval-string-last "")` is called
- **THEN** the return value is void

### Requirement: sandbox.js uses eval-string instead of JS parser
The sandbox SHALL call ECE's `eval-string` (for Run) and `eval-string-last` (for REPL) instead of parsing source with JavaScript. The `parseScheme()` and `buildECEValue()` functions SHALL be removed from `sandbox.js`.

#### Scenario: Run button evaluates via ECE reader
- **WHEN** a user clicks Run with source `(display "hello")` in the editor
- **THEN** the sandbox calls `eval-string` with the source string and "hello" appears in the console

#### Scenario: REPL evaluates via ECE reader and displays result
- **WHEN** a user enters `(+ 1 2)` in the REPL
- **THEN** the sandbox calls `eval-string-last`, receives `3`, and displays it

#### Scenario: Quasiquote works in sandbox
- **WHEN** a user runs `` `(a ,(+ 1 2) b) `` in the sandbox
- **THEN** the expression evaluates correctly (this would have failed with the old JS parser)
