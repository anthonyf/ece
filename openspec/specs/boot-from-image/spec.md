## Requirements

### Requirement: boot.lisp provides evaluate without the CL compiler
`boot.lisp` SHALL load the bootstrap image and provide the `evaluate` CL function by delegating to the metacircular compiler's `mc-compile-and-go`. The function signature SHALL be `(evaluate expr &optional env)`, matching the current compiler.lisp signature exactly.

#### Scenario: evaluate with no env uses global environment
- **WHEN** `(evaluate '(+ 1 2))` is called without an env argument
- **THEN** the result SHALL be `3`
- **AND** the global environment SHALL be used for variable lookups

#### Scenario: evaluate with explicit env
- **WHEN** `(evaluate 'x (list (cons '(x) '(42))))` is called
- **THEN** the result SHALL be `42`

#### Scenario: evaluate with nil env
- **WHEN** `(evaluate 4 nil)` is called with nil as the env
- **THEN** the result SHALL be `4`
- **AND** the nil env SHALL be passed through (not defaulted to global)

### Requirement: boot.lisp provides ece-try-eval for error handling
`boot.lisp` SHALL define `ece-try-eval` as a CL function that wraps `evaluate` with error handling. The image's existing `(primitive ece-try-eval)` binding SHALL work via CL `symbol-function` lookup.

#### Scenario: Successful evaluation
- **WHEN** `ece-try-eval` is called with a valid expression
- **THEN** the result SHALL be returned

#### Scenario: Error handling
- **WHEN** `ece-try-eval` is called with an expression that signals an error
- **THEN** the error message SHALL be printed
- **AND** nil SHALL be returned

### Requirement: boot.lisp provides repl function
`boot.lisp` SHALL define a `repl` CL function that starts the ECE REPL using the metacircular compiler from the image.

#### Scenario: REPL startup
- **WHEN** `(ece:repl)` is called after loading the `"ece"` ASDF system
- **THEN** the ECE REPL SHALL start and accept user input

### Requirement: ece ASDF system loads boot.lisp instead of compiler.lisp
The `"ece"` ASDF system SHALL load `runtime.lisp` followed by `boot.lisp`. It SHALL NOT load `compiler.lisp`.

#### Scenario: Normal system load
- **WHEN** `(asdf:load-system :ece)` is evaluated
- **THEN** `runtime.lisp` and `boot.lisp` SHALL be loaded
- **AND** the bootstrap image SHALL be restored
- **AND** `evaluate`, `ece-try-eval`, and `repl` SHALL be available

### Requirement: ece/cold ASDF system loads compiler.lisp for cold boot
A separate `"ece/cold"` ASDF system SHALL load `runtime.lisp` followed by `compiler.lisp`, providing the full CL bootstrap compiler for image generation.

#### Scenario: Cold boot for image generation
- **WHEN** `(asdf:load-system :ece/cold)` is evaluated
- **THEN** the CL bootstrap compiler SHALL be loaded
- **AND** `ece-save-image` SHALL be callable to generate a new bootstrap image
