## MODIFIED Requirements

### Requirement: compile-and-go compiles and executes an expression
`compile-and-go` SHALL compile an expression into instructions, assemble them using the ECE assembler (after bootstrap), and execute them, returning the result.

#### Scenario: Simple expression
- **WHEN** `(compile-and-go '(+ 1 2))` is called
- **THEN** the result SHALL be `3`

#### Scenario: Define and use
- **WHEN** `(compile-and-go '(begin (define x 42) x))` is called
- **THEN** the result SHALL be `42`

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
