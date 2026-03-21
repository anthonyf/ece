## MODIFIED Requirements

### Requirement: Assembler primitives implemented on WASM
All assembler-support primitives (IDs 85, 92-97, 125-135) SHALL have working WASM implementations instead of stubs.

#### Scenario: %space-instruction-push! adds instruction
- **WHEN** `(%space-instruction-push! space-id instr)` is called
- **THEN** the instruction SHALL be converted to a `$instr` struct and appended to the space's instruction vector

#### Scenario: %space-label-set! registers label
- **WHEN** `(%space-label-set! space-id label pc)` is called
- **THEN** the label-PC mapping SHALL be stored in the space's label table

#### Scenario: execute-from-pc runs code
- **WHEN** `(execute-from-pc pc)` is called with a qualified address
- **THEN** the executor SHALL recursively run from that address and return the result
