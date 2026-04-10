## MODIFIED Requirements

### Requirement: executor dispatches halt instruction
The instruction executor SHALL recognize the `halt` instruction in its dispatch loop. When `(halt)` is encountered, the executor SHALL exit the loop immediately and return the current `val` register, equivalent to the `pc >= len` exit path.

#### Scenario: CL executor handles halt
- **WHEN** the CL `execute-instructions` function encounters `(halt)` at the current PC
- **THEN** it SHALL execute `(go loop-end)` to exit the tagbody loop
- **AND** the function SHALL return `val`

#### Scenario: WASM executor handles halt
- **WHEN** the WASM `execute-instructions` function encounters a `halt` instruction
- **THEN** it SHALL branch to the loop exit
- **AND** the function SHALL return the `val` register
