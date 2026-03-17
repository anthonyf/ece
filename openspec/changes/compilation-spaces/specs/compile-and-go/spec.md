## MODIFIED Requirements

### Requirement: compile-and-go compiles and executes an expression
`compile-and-go` SHALL compile an expression into instructions, assemble them into a space using the ECE assembler, and execute them, returning the result. The target space is determined by context: `(load ...)` creates a new space per file; REPL expressions use the REPL space.

#### Scenario: Simple expression at REPL
- **WHEN** `(evaluate '(+ 1 2))` is called
- **THEN** the expression SHALL be compiled and assembled into the REPL space
- **AND** the result SHALL be `3`

#### Scenario: Define and use at REPL
- **WHEN** `(evaluate '(begin (define x 42) x))` is called
- **THEN** both the define and the reference SHALL be assembled into the REPL space
- **AND** the result SHALL be `42`

### Requirement: load creates a new space per file
`(load "file.scm")` SHALL create a new compilation space named after the file, compile all forms in the file, and assemble them into that space. Macro definitions encountered during compilation SHALL be available to subsequent forms in the same file and to later `(load ...)` calls.

#### Scenario: Load creates named space
- **WHEN** `(load "stdlib.scm")` is called
- **THEN** a new space named `"stdlib"` SHALL be created in the space registry
- **AND** all forms in `stdlib.scm` SHALL be assembled into that space
- **AND** the space SHALL be registered with a sequential space ID

#### Scenario: Multiple loads create separate spaces
- **WHEN** `(load "prelude.scm")` followed by `(load "stdlib.scm")` is called
- **THEN** two separate spaces SHALL exist in the registry
- **AND** each space SHALL have its own instruction array with PCs starting at 0

#### Scenario: Cross-file procedure calls work
- **WHEN** `prelude.scm` defines `map` and `stdlib.scm` calls `map`
- **THEN** the call SHALL succeed via `lookup-variable-value` in the global environment
- **AND** execution SHALL transition from stdlib's space to prelude's space through the dispatcher

### Requirement: compilation pipeline uses ECE assembler targeting spaces
After the ECE assembler is loaded during bootstrap, `compile-and-go` and `mc-compile-and-go` SHALL use the ECE assembler targeting the current space instead of the global vector.

#### Scenario: ECE assembler targets current space
- **WHEN** an expression is compiled after bootstrap during a `(load "file.scm")`
- **THEN** the instruction list SHALL be assembled into the space created for that file
- **AND** labels SHALL be registered in the space's local label table
