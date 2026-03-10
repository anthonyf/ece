## ADDED Requirements

### Requirement: assembler appends instructions to global vector
The ECE assembler SHALL walk an instruction list, appending non-label instructions to the global instruction vector and resolving operations. It SHALL return the start PC (the index of the first appended instruction).

#### Scenario: Assemble simple instructions
- **WHEN** `(assemble-into-global '((assign val (const 42))))` is called
- **THEN** the instruction SHALL be appended to the global instruction vector and the start PC SHALL be returned

#### Scenario: Start PC reflects prior instructions
- **WHEN** instructions are assembled after previous compilations
- **THEN** the returned start PC SHALL equal the length of the instruction vector before assembly

### Requirement: assembler registers labels in label table
The ECE assembler SHALL recognize symbols in the instruction list as labels and register them in the global label table with their PC (position in the instruction vector).

#### Scenario: Label registration
- **WHEN** `(assemble-into-global '(my-label (assign val (const 1))))` is called
- **THEN** the label `my-label` SHALL be registered at the PC of the following instruction

### Requirement: assembler handles procedure-name pseudo-instructions
The ECE assembler SHALL recognize `(procedure-name label name)` pseudo-instructions and register the mapping from the label's PC to the procedure name in the procedure name table.

#### Scenario: Procedure name registration
- **WHEN** instructions containing `(procedure-name entry-1 my-func)` are assembled and `entry-1` was previously registered as a label
- **THEN** the PC for `entry-1` SHALL be mapped to `my-func` in the procedure name table

### Requirement: assembler resolves operations
The ECE assembler SHALL resolve `(op name)` forms in instructions to function references at assembly time, producing the same resolved form as the CL assembler.

#### Scenario: Operation resolution
- **WHEN** an instruction `(assign val (op lookup-variable-value) (const x) (reg env))` is assembled
- **THEN** the stored instruction SHALL have the operation name resolved to its function reference

### Requirement: assembler produces identical results to CL assembler
The ECE assembler SHALL produce identical instruction vector contents and label table entries as the CL `assemble-into-global` for the same input.

#### Scenario: Round-trip equivalence
- **WHEN** a compiled expression is assembled by the ECE assembler
- **THEN** executing from the returned start PC SHALL produce the same result as the CL assembler would
