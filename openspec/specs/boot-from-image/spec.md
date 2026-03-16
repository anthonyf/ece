## Requirements

### Requirement: runtime.lisp provides evaluate without the CL compiler
`runtime.lisp` SHALL load the bootstrap image using the flat-format deserializer and provide the `evaluate` CL function by delegating to the metacircular compiler's `mc-compile-and-go`. The function signature SHALL be `(evaluate expr &optional env)`, matching the current compiler.lisp signature exactly. No CL readtable SHALL be required for image loading.

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

### Requirement: runtime.lisp provides ece-try-eval for error handling
`runtime.lisp` SHALL define `ece-try-eval` as a CL function that wraps `evaluate` with error handling. The image's existing `(primitive ece-try-eval)` binding SHALL work via CL `symbol-function` lookup.

#### Scenario: Successful evaluation
- **WHEN** `ece-try-eval` is called with a valid expression
- **THEN** the result SHALL be returned

#### Scenario: Error handling
- **WHEN** `ece-try-eval` is called with an expression that signals an error
- **THEN** the error message SHALL be printed
- **AND** nil SHALL be returned

### Requirement: runtime.lisp provides repl function
`runtime.lisp` SHALL define a `repl` CL function that starts the ECE REPL using the metacircular compiler from the image.

#### Scenario: REPL startup
- **WHEN** `(ece:repl)` is called after loading the `"ece"` ASDF system
- **THEN** the ECE REPL SHALL start and accept user input

### Requirement: ece ASDF system loads only runtime.lisp
The `"ece"` ASDF system SHALL load only `runtime.lisp`. The image load, `evaluate`, `ece-try-eval`, and `repl` definitions (previously in `boot.lisp`) SHALL be included in `runtime.lisp`. Neither `boot.lisp` nor `readtable.lisp` SHALL be loaded. The runtime SHALL NOT contain CL readtable infrastructure (`*ece-readtable*`, reader macros).

#### Scenario: Normal system load
- **WHEN** `(asdf:load-system :ece)` is evaluated
- **THEN** only `runtime.lisp` SHALL be loaded
- **AND** the bootstrap image SHALL be restored using the flat-format deserializer
- **AND** `evaluate`, `ece-try-eval`, and `repl` SHALL be available
- **AND** no CL readtable customization SHALL be required

### Requirement: ece/cold ASDF system loads compiler.lisp for cold boot
A separate `"ece/cold"` ASDF system SHALL load `runtime.lisp`, `readtable.lisp`, and `compiler.lisp`, providing the full CL bootstrap compiler and readtable for image generation from source.

#### Scenario: Cold boot for image generation
- **WHEN** `(asdf:load-system :ece/cold)` is evaluated
- **THEN** the CL bootstrap compiler and readtable SHALL be loaded
- **AND** `ece-save-image` SHALL be callable to generate a new bootstrap image
