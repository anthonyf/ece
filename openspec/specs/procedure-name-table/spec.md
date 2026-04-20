## Purpose
Attach defined names to compiled procedure code objects, enabling meaningful procedure display in error messages, backtraces, and REPL output. Names are stored directly on the code object's metadata, not in a side table.

## Requirements

### Requirement: compiler registers procedure names at define time

When the compiler translates a `(define (name ...) ...)` form (or equivalent), the compiler SHALL attach the defined name to the resulting code object's name field. Alternatively, the compiler MAY emit a `(procedure-name <name>)` pseudo-instruction that the assembler consumes by writing the name onto the code object being built. Either approach is acceptable; the requirement is that the name reaches the code object's name field before compilation completes.

#### Scenario: Name is attached to the code object

- **WHEN** `(define (f x) (+ x 1))` is compiled
- **THEN** the resulting code object's name field SHALL contain `f`

#### Scenario: Variable-form define does not set a name

- **WHEN** `(define x 42)` is compiled (value is not a lambda)
- **THEN** no code object is involved for this define form
- **AND** nothing is written to a code-object name field

### Requirement: assembler attaches procedure names to code objects

The ECE assembler SHALL recognize `(procedure-name <name>)` pseudo-instructions (or equivalent structural mechanism) and write the name onto the code object currently being assembled. The pseudo-instruction SHALL NOT be emitted as a real instruction in the instruction vector.

#### Scenario: Pseudo-instruction writes the code-object name field

- **WHEN** the assembler processes `(procedure-name f)` in the course of assembling a code object
- **THEN** the resulting code object's name field SHALL be `f`

#### Scenario: Pseudo-instruction is not in instruction vector

- **WHEN** the assembler processes a `(procedure-name ...)` pseudo-instruction
- **THEN** the resulting code object's instruction vector SHALL NOT contain any `procedure-name` instruction

### Requirement: procedure name lookup by code object

`format-ece-proc` and other diagnostic formatters SHALL read the name field of a compiled procedure's code object and display that name when non-`#f`. When the name field is `#f`, formatters SHALL fall back to a human-readable identifier for the code object (such as its address or an index).

#### Scenario: Named procedure displays name

- **WHEN** a compiled procedure whose code object's name field is `f` is formatted
- **THEN** `format-ece-proc` SHALL return a string containing `f`

#### Scenario: Unnamed procedure uses a fallback identifier

- **WHEN** a compiled procedure whose code object's name field is `#f` is formatted
- **THEN** `format-ece-proc` SHALL fall back to a human-readable identifier for the code object (no `*procedure-name-table*` lookup)
