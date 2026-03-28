## ADDED Requirements

### Requirement: Register machine with 6 registers
The WASM executor SHALL maintain 6 registers as WASM locals of type `(ref null eq)`: `val`, `env`, `proc`, `argl`, `continue`, and `stack`.

#### Scenario: Registers initialized at entry
- **WHEN** the executor starts with an initial environment and PC
- **THEN** `env` SHALL be set to the initial environment, `pc` to the initial program counter, and all other registers SHALL be null/empty

### Requirement: Execute assign instruction
The executor SHALL implement the `assign` opcode, which sets a register to a value from a constant, another register, a label address, or an operation result.

#### Scenario: Assign from constant
- **WHEN** the instruction is `(assign val (const 42))`
- **THEN** register `val` SHALL be set to the fixnum 42

#### Scenario: Assign from register
- **WHEN** the instruction is `(assign val (reg proc))`
- **THEN** register `val` SHALL be set to the current value of register `proc`

#### Scenario: Assign from label
- **WHEN** the instruction is `(assign continue (label foo))`
- **THEN** register `continue` SHALL be set to a space-qualified address `(space-id . pc)` for label `foo`

#### Scenario: Assign from operation
- **WHEN** the instruction is `(assign val (op-fn <fn>) (reg argl))`
- **THEN** the operation function SHALL be called with the evaluated operands and the result stored in `val`

### Requirement: Execute test instruction
The executor SHALL implement the `test` opcode, which calls an operation and stores the boolean result in the `flag` register.

#### Scenario: Test sets flag
- **WHEN** the instruction is `(test (op-fn <fn>) (reg val))`
- **THEN** the `flag` SHALL be set to the boolean result of calling the operation

### Requirement: Execute branch instruction
The executor SHALL implement the `branch` opcode, which jumps to a label if `flag` is true (non-false).

#### Scenario: Branch taken
- **WHEN** the instruction is `(branch (label foo))` and `flag` is true
- **THEN** `pc` SHALL be set to the PC of label `foo`

#### Scenario: Branch not taken
- **WHEN** the instruction is `(branch (label foo))` and `flag` is false
- **THEN** `pc` SHALL advance to the next instruction

### Requirement: Execute goto instruction
The executor SHALL implement the `goto` opcode, which unconditionally jumps to a label or register address.

#### Scenario: Goto label
- **WHEN** the instruction is `(goto (label foo))`
- **THEN** `pc` SHALL be set to the PC of label `foo`

#### Scenario: Goto register with cross-space address
- **WHEN** the instruction is `(goto (reg continue))` and `continue` holds a space-qualified address in a different space
- **THEN** the executor SHALL switch to the target space and set `pc` to the target PC

#### Scenario: Goto register with same-space address
- **WHEN** the instruction is `(goto (reg continue))` and `continue` holds an address in the current space
- **THEN** `pc` SHALL be set to the local PC without switching spaces

### Requirement: Execute save and restore instructions
The executor SHALL implement `save` (push register onto stack) and `restore` (pop stack into register).

#### Scenario: Save and restore round-trip
- **WHEN** `save val` is executed when `val` is 42, followed by `restore val` after `val` has been changed
- **THEN** `val` SHALL be 42 after the restore

### Requirement: Execute perform instruction
The executor SHALL implement the `perform` opcode, which calls an operation for its side effects (result discarded).

#### Scenario: Perform calls operation
- **WHEN** the instruction is `(perform (op-fn <fn>) (reg val) (reg env))`
- **THEN** the operation function SHALL be called with the evaluated operands

### Requirement: Compilation space registry
The executor SHALL maintain a registry of compilation spaces, each with its own instruction vector and label table. Cross-space jumps SHALL switch the active space.

#### Scenario: Load and register a space
- **WHEN** a `.ececb` file is loaded with space name "prelude"
- **THEN** a compilation space SHALL be created and registered under the symbol `prelude`

#### Scenario: Cross-space function call
- **WHEN** a compiled procedure entry points to space "prelude" and the executor is in space "bootstrap"
- **THEN** the executor SHALL switch to the "prelude" space's instruction vector and label table before jumping to the target PC

### Requirement: Instruction loop terminates at end of vector
The executor SHALL stop when PC reaches the end of the current instruction vector and return the value in the `val` register.

#### Scenario: Normal termination
- **WHEN** PC equals the length of the instruction vector
- **THEN** the executor SHALL exit the loop and return the contents of register `val`
