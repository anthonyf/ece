## ADDED Requirements

### Requirement: halt instruction terminates executor
The register machine SHALL support a `halt` instruction. When the executor encounters `(halt)`, it SHALL immediately exit the execution loop and return the current value of the `val` register, identical to the behavior when `pc >= len`.

#### Scenario: halt stops execution
- **WHEN** the executor encounters a `(halt)` instruction
- **THEN** the execution loop SHALL exit immediately
- **AND** the return value SHALL be the current contents of the `val` register

#### Scenario: halt after compiled expression
- **WHEN** a REPL expression evaluates to `42` and is followed by a `halt` instruction
- **THEN** the executor SHALL return `42`
- **AND** no instructions after the `halt` SHALL execute

#### Scenario: halt prevents fall-through between compilation units
- **WHEN** a continuation captured in REPL expression N is invoked from expression N+1
- **AND** expression N's compiled code is followed by a `halt` instruction
- **THEN** after the continuation replays expression N's code, execution SHALL stop at the `halt`
- **AND** execution SHALL NOT fall through into expression N+1's instructions

### Requirement: halt passes through assembler unchanged
The `halt` instruction SHALL require no operation resolution. Both the CL assembler (`resolve-operations`) and the ECE assembler SHALL pass `(halt)` through as a regular instruction without transformation.

#### Scenario: CL assembler handles halt
- **WHEN** `resolve-operations` processes `(halt)`
- **THEN** it SHALL return `(halt)` unchanged (via the default `t` case)

#### Scenario: ECE assembler handles halt
- **WHEN** `ece-assemble-into-global` encounters `(halt)` in the instruction list
- **THEN** it SHALL push `(halt)` to the instruction vector as a regular instruction
