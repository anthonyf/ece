## ADDED Requirements

### Requirement: ecec-op-id resolves all registered operations
The `$ecec-op-id` function SHALL resolve all operation names registered in the asm-sym-ids table, including the final slot.

#### Scenario: do-continuation-winds resolves to op 22
- **WHEN** the ecec text loader parses `(perform (op do-continuation-winds) (reg proc))`
- **THEN** the instruction's c field SHALL be 22 (not -1)

#### Scenario: all bootstrap spaces pass validation
- **WHEN** `make test-wasm` runs space validation on prelude, compiler, reader, assembler, and compilation-unit
- **THEN** all 5 spaces SHALL validate successfully (return 0)
