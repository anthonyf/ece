## MODIFIED Requirements

### Requirement: boot.lisp provides evaluate without the CL compiler
`boot.lisp` SHALL load the bootstrap image using the flat-format deserializer and provide the `evaluate` CL function by delegating to the metacircular compiler's `mc-compile-and-go`. The function signature SHALL be `(evaluate expr &optional env)`, matching the current compiler.lisp signature exactly. No CL readtable SHALL be required for image loading.

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

### Requirement: ece ASDF system loads boot.lisp instead of compiler.lisp
The `"ece"` ASDF system SHALL load `runtime.lisp` followed by `boot.lisp`. It SHALL NOT load `compiler.lisp`. The runtime SHALL NOT contain CL readtable infrastructure (`*ece-readtable*`, reader macros, `ece-read`).

#### Scenario: Normal system load
- **WHEN** `(asdf:load-system :ece)` is evaluated
- **THEN** `runtime.lisp` and `boot.lisp` SHALL be loaded
- **AND** the bootstrap image SHALL be restored using the flat-format deserializer
- **AND** `evaluate`, `ece-try-eval`, and `repl` SHALL be available
- **AND** no CL readtable customization SHALL be required

### Requirement: ece/cold ASDF system loads compiler.lisp for cold boot
A separate `"ece/cold"` ASDF system SHALL load `runtime.lisp` followed by `compiler.lisp`, providing the full CL bootstrap compiler for image generation. The cold boot system retains the CL reader for reading `.scm` source files during the bootstrap process.

#### Scenario: Cold boot for image generation
- **WHEN** `(asdf:load-system :ece/cold)` is evaluated
- **THEN** the CL bootstrap compiler SHALL be loaded
- **AND** `ece-save-image` SHALL be callable to generate a new bootstrap image in flat format
