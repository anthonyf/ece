## ADDED Requirements

### Requirement: executor runs instruction sequences on register machine
The instruction executor SHALL execute a list of register machine instructions, manipulating the registers `stack`, `val`, `env`, `proc`, `argl`, and a program counter. The assembler SHALL maintain a parallel source vector of unresolved instructions alongside the resolved execution vector.

#### Scenario: Assign constant
- **WHEN** instruction `(assign val (const 42))` is executed
- **THEN** the `val` register SHALL be set to `42`

#### Scenario: Assign from register
- **WHEN** instruction `(assign proc (reg val))` is executed
- **THEN** the `proc` register SHALL be set to the current value of `val`

#### Scenario: Assign from operation
- **WHEN** instruction `(assign val (op lookup-variable-value) (const x) (reg env))` is executed
- **THEN** `val` SHALL be set to the result of calling `lookup-variable-value` with symbol `x` and the current `env`

#### Scenario: Source instructions are preserved
- **WHEN** instructions are assembled into the global vector via `assemble-into-global`
- **THEN** the original unresolved instructions (with `(op name)` forms) SHALL be stored in `*global-instruction-source*`
- **AND** the resolved instructions (with `(op-fn #<function>)` forms) SHALL be stored in `*global-instruction-vector*`
- **AND** both vectors SHALL have the same length and correspondence

### Requirement: executor supports control flow instructions
The executor SHALL support `test`, `branch`, `goto`, and `label` instructions for control flow.

#### Scenario: Branch taken
- **WHEN** `(test (op false?) (reg val))` is executed and `val` is falsy
- **AND** the next instruction is `(branch (label L1))`
- **THEN** the program counter SHALL jump to label `L1`

#### Scenario: Branch not taken
- **WHEN** `(test (op false?) (reg val))` is executed and `val` is truthy
- **AND** the next instruction is `(branch (label L1))`
- **THEN** execution SHALL continue to the instruction after the branch

#### Scenario: Goto label
- **WHEN** `(goto (label L1))` is executed
- **THEN** the program counter SHALL jump to label `L1`

#### Scenario: Goto register
- **WHEN** `(goto (reg continue))` is executed
- **THEN** the program counter SHALL jump to the address stored in `continue`

### Requirement: executor supports save and restore
The executor SHALL support `(save <reg>)` and `(restore <reg>)` instructions that push/pop register values on the stack.

#### Scenario: Save and restore round-trip
- **WHEN** `(save env)` is executed, then `env` is modified, then `(restore env)` is executed
- **THEN** `env` SHALL have its original value

### Requirement: executor supports apply dispatch
The executor SHALL handle primitive procedure application and compiled procedure application.

#### Scenario: Apply primitive procedure
- **WHEN** `proc` contains a primitive and `argl` contains arguments
- **AND** a `(perform (op apply-primitive))` instruction is executed
- **THEN** `val` SHALL contain the result of applying the primitive to the arguments

#### Scenario: Apply compiled procedure
- **WHEN** `proc` contains a compiled-procedure with an entry label
- **THEN** the executor SHALL extend `env` with the procedure's parameters and arguments
- **AND** jump to the entry label to execute the compiled body
