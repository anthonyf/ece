## Requirements

### Requirement: assembler returns a code object

The ECE assembler SHALL walk an instruction list and produce a fresh code object containing that list's non-label instructions and a label table whose entries map labels (symbols) to local PCs within the code object's instruction vector. The assembler SHALL NOT append to a shared global instruction vector, and SHALL NOT mutate any "current space" state.

#### Scenario: assemble produces a fresh code object

- **WHEN** `(assemble '((assign val (const 42))))` is called
- **THEN** the return value SHALL satisfy `code-object?`
- **AND** the code object's instruction vector SHALL contain exactly the instruction `(assign val (const 42))`

#### Scenario: assemble is mutation-free

- **WHEN** `(assemble '((assign val (const 1))))` is called twice in succession
- **THEN** each call SHALL return a fresh, distinct code object
- **AND** no prior return value SHALL be mutated

### Requirement: assembler registers labels local to the code object

The ECE assembler SHALL recognize symbols in the instruction list as labels and register them in the code object's own label table with their local PC. Labels SHALL NOT be visible across code objects.

#### Scenario: Label registration

- **WHEN** `(assemble '(my-label (assign val (const 1))))` is called
- **THEN** the resulting code object's label table SHALL map `my-label` to the local PC of the `(assign val (const 1))` instruction

#### Scenario: Label namespace is per-code-object

- **WHEN** two code objects are assembled, both containing a label named `L1`
- **THEN** each code object's label table SHALL have its own independent entry for `L1`
- **AND** the two entries SHALL NOT collide

### Requirement: assembler handles procedure-name pseudo-instructions

The ECE assembler SHALL recognize `(procedure-name <name>)` pseudo-instructions and write the name onto the code object's name metadata field. The pseudo-instruction SHALL NOT be emitted as a real instruction.

#### Scenario: Procedure name registration

- **WHEN** instructions containing `(procedure-name my-func)` are assembled
- **THEN** the resulting code object's name field SHALL be `my-func`

### Requirement: assembler resolves operations

The ECE assembler SHALL resolve `(op name)` forms in instructions to function references at assembly time, storing them in the code object's resolved-instructions vector (separate from the source-instructions vector used for introspection).

#### Scenario: Operation resolution

- **WHEN** an instruction `(assign val (op lookup-variable-value) (const x) (reg env))` is assembled
- **THEN** the code object's resolved-instructions vector SHALL contain the instruction with the operation name replaced by its function reference
- **AND** the code object's source-instructions vector SHALL retain the original symbolic form
