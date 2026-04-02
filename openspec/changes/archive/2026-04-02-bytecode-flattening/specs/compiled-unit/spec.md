## MODIFIED Requirements

### Requirement: write-compiled-unit serializes to a port
`write-compiled-unit` SHALL write a compiled unit to an output port with one instruction per line. Gensym labels in the instruction list SHALL be renamed to deterministic symbols (`$L0`, `$L1`, ...) for stable serialization.

#### Scenario: Serialize a compiled unit
- **WHEN** `(write-compiled-unit (compile-form '(+ 1 2)) port)` is called
- **THEN** the compiled unit is written to the port with one instruction per line

#### Scenario: Gensyms are renamed
- **WHEN** a compiled unit containing gensym labels is serialized
- **THEN** the output contains deterministic label names like `$L0`, `$L1` instead of gensym names

#### Scenario: Labels appear on their own line
- **WHEN** a compiled unit with labels is written
- **THEN** each label appears on its own line, indented to the same level as instructions
