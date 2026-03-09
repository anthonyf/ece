## ADDED Requirements

### Requirement: compile-and-go compiles and executes an expression
`compile-and-go` SHALL compile an expression into instructions and execute them, returning the result.

#### Scenario: Simple expression
- **WHEN** `(compile-and-go '(+ 1 2))` is called
- **THEN** the result SHALL be `3`

#### Scenario: Define and use
- **WHEN** `(compile-and-go '(begin (define x 42) x))` is called
- **THEN** the result SHALL be `42`

### Requirement: evaluate delegates to compile-and-go
`evaluate` SHALL call `compile-and-go` internally, so all existing code that calls `evaluate` gets compiled execution transparently.

#### Scenario: Existing test compatibility
- **WHEN** `(evaluate '(+ 1 2))` is called
- **THEN** the result SHALL be `3` (same as before, but now compiled)

#### Scenario: Evaluate with custom environment
- **WHEN** `(evaluate expr env)` is called with a custom environment
- **THEN** the compiled code SHALL execute in that environment

### Requirement: compile-file compiles all forms in a file
`compile-file` SHALL read all forms from a file using the ECE readtable and compile-and-execute them sequentially. Macro definitions encountered during compilation SHALL be available to subsequent forms.

#### Scenario: Prelude compilation
- **WHEN** `(compile-file "src/prelude.scm")` is called
- **THEN** all prelude definitions (map, filter, reduce, macros) SHALL be available in the global environment

#### Scenario: Macro bootstrap
- **WHEN** a file defines `cond` macro then uses `cond` in a later form
- **THEN** the `cond` usage SHALL be expanded at compile time using the previously defined macro
