## MODIFIED Requirements

### Requirement: write-compiled-unit serializes to a port

Writes a compiled unit to an output port as an s-expression. `write-compiled-unit` MUST work correctly when called from within compiled ECE code (not just from the CL top-level). Label references in the compiled unit's instruction sequence MUST be self-contained — they SHALL NOT depend on labels registered in the caller's execution space.

#### Scenario: Serialize a compiled unit
- **WHEN** a compiled unit is written to a port
- **THEN** the output is a valid s-expression representing the instructions

#### Scenario: Gensym labels are serialized correctly
- **WHEN** a compiled unit containing gensym labels is written
- **THEN** the labels are serialized in a form that remains valid and can be read back by `read-compiled-unit`

#### Scenario: Round-trip from compiled context
- **WHEN** `write-compiled-unit` is called from within a running ECE test (compiled code), and the output is read back with `read-compiled-unit`
- **THEN** the round-trip produces an equivalent compiled unit

#### Scenario: Round-trip with definition
- **WHEN** a compiled unit containing a `define` form is written and read back
- **THEN** the round-tripped unit executes correctly and the definition is available
