## ADDED Requirements

### Requirement: compile-form returns a compiled unit
`compile-form` SHALL accept a single ECE expression and return a compiled unit value. The compiled unit contains the flat instruction list produced by `mc-compile`.

#### Scenario: Compile a simple expression
- **WHEN** `(compile-form '(+ 1 2))` is called
- **THEN** a compiled unit value is returned

#### Scenario: Compile a definition
- **WHEN** `(compile-form '(define x 42))` is called
- **THEN** a compiled unit value is returned that, when executed, defines `x` in the global environment

### Requirement: compiled-unit? predicate
`compiled-unit?` SHALL return `#t` for compiled unit values and `#f` for all other values.

#### Scenario: Compiled unit is recognized
- **WHEN** `(compiled-unit? (compile-form '(+ 1 2)))` is called
- **THEN** the result is `#t`

#### Scenario: Non-compiled-unit is rejected
- **WHEN** `(compiled-unit? 42)` is called
- **THEN** the result is `#f`

### Requirement: compiled-unit-instructions accessor
`compiled-unit-instructions` SHALL return the flat instruction list from a compiled unit.

#### Scenario: Access instructions
- **WHEN** `(compiled-unit-instructions (compile-form '(+ 1 2)))` is called
- **THEN** a list of symbolic instructions is returned (the same form consumed by `assemble-into-global`)

### Requirement: execute runs a compiled unit
`execute` SHALL assemble a compiled unit's instructions into the global instruction vector and execute them, returning the result value.

#### Scenario: Execute a compiled expression
- **WHEN** `(execute (compile-form '(+ 1 2)))` is called
- **THEN** the result is `3`

#### Scenario: Execute a definition
- **WHEN** `(execute (compile-form '(define x 42)))` is called
- **THEN** `x` is defined in the global environment with value `42`

#### Scenario: Execute multiple units in sequence
- **WHEN** a compiled unit defining `(define y 10)` is executed, followed by a compiled unit for `(+ y 5)`
- **THEN** the second unit returns `15`

### Requirement: write-compiled-unit serializes to a port
`write-compiled-unit` SHALL write a compiled unit to an output port as an s-expression. Gensym labels in the instruction list SHALL be renamed to deterministic symbols (`$L0`, `$L1`, ...) for stable serialization.

#### Scenario: Serialize a compiled unit
- **WHEN** `(write-compiled-unit (compile-form '(+ 1 2)) port)` is called
- **THEN** the compiled unit is written to the port as a readable s-expression

#### Scenario: Gensyms are renamed
- **WHEN** a compiled unit containing gensym labels is serialized
- **THEN** the output contains deterministic label names like `$L0`, `$L1` instead of gensym names

### Requirement: read-compiled-unit deserializes from a port
`read-compiled-unit` SHALL read a serialized compiled unit from an input port and return a compiled unit value. It SHALL return an eof value when the port is exhausted.

#### Scenario: Round-trip serialization
- **WHEN** a compiled unit is written with `write-compiled-unit` and read back with `read-compiled-unit`
- **THEN** executing the deserialized unit produces the same result as executing the original

#### Scenario: EOF on empty port
- **WHEN** `read-compiled-unit` is called on an exhausted port
- **THEN** an eof value is returned
