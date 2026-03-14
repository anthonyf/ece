## Requirements

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

### Requirement: executor supports lexical-ref operation
The instruction executor SHALL support the `lexical-ref` operation, which takes a depth (integer), offset (integer), and environment, and returns the value at that position.

#### Scenario: Assign from lexical-ref
- **WHEN** instruction `(assign val (op lexical-ref) (const 0) (const 1) (reg env))` is executed
- **AND** the innermost frame of `env` is a vector `#(10 20 30)`
- **THEN** `val` SHALL be set to `20`

#### Scenario: Lexical-ref across frames
- **WHEN** instruction `(assign val (op lexical-ref) (const 2) (const 0) (reg env))` is executed
- **AND** the environment has 3+ frames
- **THEN** `val` SHALL be set to offset 0 of the frame at depth 2

### Requirement: executor supports lexical-set! operation
The instruction executor SHALL support the `lexical-set!` operation via the `perform` instruction, which takes a depth, offset, value, and environment, and mutates the frame slot.

#### Scenario: Perform lexical-set!
- **WHEN** instruction `(perform (op lexical-set!) (const 0) (const 0) (reg val) (reg env))` is executed
- **AND** `val` is `42` and the innermost frame is a vector
- **THEN** offset 0 of the innermost frame SHALL become `42`

### Requirement: executor resolves lexical operations at assembly time
The `resolve-operations` function SHALL resolve `lexical-ref` and `lexical-set!` operation names to their function pointers, just like existing operations.

#### Scenario: Operation resolution
- **WHEN** an instruction containing `(op lexical-ref)` is assembled
- **THEN** `resolve-operations` SHALL convert it to `(op-fn #<function lexical-ref>)`
