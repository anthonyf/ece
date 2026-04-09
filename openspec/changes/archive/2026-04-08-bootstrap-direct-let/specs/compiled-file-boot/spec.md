## MODIFIED Requirements

### Requirement: Bootstrap handles enclosing-environment operation
The bootstrap .ecec file SHALL contain compiled instructions that reference the `enclosing-environment` operation (op-id 27). The CL and WASM runtimes SHALL resolve this operation during instruction assembly.

#### Scenario: Boot from .ecec with enclosing-environment instructions
- **WHEN** loading a bootstrap.ecec compiled by the new compiler (with direct let/let* compilation)
- **THEN** all `(op enclosing-environment)` references SHALL resolve to the runtime's `enclosing-environment` function
- **AND** the boot SHALL complete with the full global environment (400+ symbols)

#### Scenario: WASM asm symbol table includes enclosing-environment
- **WHEN** the WASM runtime initializes its asm symbol table
- **THEN** `enclosing-environment` SHALL be registered at slot 44 (op-id 27 + offset 17)
- **AND** the total asm symbol count SHALL be 45
