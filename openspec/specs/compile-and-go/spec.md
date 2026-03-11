## Requirements

### Requirement: compile-and-go compiles and executes an expression
`compile-and-go` SHALL compile an expression into instructions, assemble them using the ECE assembler (after bootstrap), and execute them, returning the result. The CL function `evaluate` delegates to `mc-compile-and-go` in the image (via `boot.lisp`) rather than to the CL `compile-and-go` function. The CL `compile-and-go` function remains available only through the `"ece/cold"` ASDF system.

#### Scenario: Simple expression
- **WHEN** `(evaluate '(+ 1 2))` is called via boot.lisp
- **THEN** the result SHALL be `3`

#### Scenario: Define and use
- **WHEN** `(evaluate '(begin (define x 42) x))` is called via boot.lisp
- **THEN** the result SHALL be `42`

#### Scenario: evaluate with custom environment
- **WHEN** `(evaluate expr env)` is called with a custom environment
- **THEN** `mc-compile-and-go` SHALL receive the environment
- **AND** variable lookups SHALL use the provided environment

### Requirement: compile-file compiles all forms in a file
`compile-file` SHALL read all forms from a file using the ECE reader (after bootstrap) and compile-and-execute them sequentially. Macro definitions encountered during compilation SHALL be available to subsequent forms.

#### Scenario: Prelude compilation
- **WHEN** `(compile-file "src/prelude.scm")` is called
- **THEN** all prelude definitions (map, filter, reduce, macros) SHALL be available in the global environment

#### Scenario: Macro bootstrap
- **WHEN** a file defines `cond` macro then uses `cond` in a later form
- **THEN** the `cond` usage SHALL be expanded at compile time using the previously defined macro

### Requirement: compilation pipeline uses ECE assembler after bootstrap
After the ECE assembler is loaded during bootstrap, `compile-and-go` and `mc-compile-and-go` SHALL use the ECE assembler instead of CL's `assemble-into-global`.

#### Scenario: ECE assembler integration
- **WHEN** an expression is compiled after bootstrap
- **THEN** the instruction list SHALL be assembled by the ECE assembler
- **AND** the result SHALL be identical to using the CL assembler
