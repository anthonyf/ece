## MODIFIED Requirements

### Requirement: compile-and-go compiles and executes an expression
`compile-and-go` SHALL compile an expression into instructions, append a `(halt)` instruction to the compiled instruction list to prevent fall-through into subsequently compiled code, assemble the resulting instruction list using the ECE assembler (after bootstrap), and execute it, returning the result. The CL function `evaluate` delegates to `mc-compile-and-go` in the image (via `boot.lisp`) rather than to the CL `compile-and-go` function. The CL `compile-and-go` function remains available only through the `"ece/cold"` ASDF system.

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

#### Scenario: halt barrier after each compilation unit
- **WHEN** `mc-compile-and-go` assembles an expression
- **THEN** a `(halt)` instruction SHALL be appended after the compiled instructions
- **AND** the `halt` SHALL be the last instruction in the compilation unit
