## MODIFIED Requirements

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
