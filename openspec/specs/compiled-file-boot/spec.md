## NEW Requirements

### Requirement: CL-side .ecec loader
The runtime SHALL provide a `load-ecec-file` function that reads a `.ecec` file, creates a named space from the header, and executes each compiled unit.

#### Scenario: Load a compiled file at boot
- **GIVEN** a `.ecec` file with header `(ecec-header (space prelude) (macros ...))`
- **WHEN** `load-ecec-file` is called with its path
- **THEN** a space named `prelude` SHALL be created in the space registry
- **AND** all compiled units SHALL be assembled into that space and executed
- **AND** macros listed in the header SHALL be registered in `*compile-time-macros*`

### Requirement: boot-from-compiled replaces image load
The runtime SHALL boot by loading `.ecec` files in order instead of restoring a monolithic image.

#### Scenario: Normal boot
- **WHEN** `(asdf:load-system :ece)` is evaluated
- **THEN** the system SHALL load `bootstrap/prelude.ecec`, `bootstrap/compiler.ecec`, `bootstrap/reader.ecec`, `bootstrap/assembler.ecec`, `bootstrap/compilation-unit.ecec` in that order
- **AND** after boot, `evaluate`, `repl`, and `(load "file.scm")` SHALL all work

#### Scenario: No image file needed
- **WHEN** the system boots
- **THEN** no `bootstrap/ece.image` file SHALL be required
- **AND** no `ece-load-image` or `ece-save-image` function SHALL exist

### Requirement: .ecec file format
A `.ecec` file SHALL begin with a metadata header s-expression followed by compiled unit instruction lists.

#### Scenario: File structure
- **GIVEN** a `.ecec` file
- **THEN** the first s-expression SHALL be `(ecec-header (space <name>) ...)`
- **AND** subsequent s-expressions SHALL be flat instruction lists (register machine instruction sequences)

### Requirement: Makefile bootstrap target
The Makefile SHALL provide a `bootstrap` target that regenerates the `.ecec` files from source.

#### Scenario: Rebuild bootstrap
- **WHEN** `make bootstrap` is run
- **THEN** each `.scm` source file SHALL be compiled to `.ecec`
- **AND** the results SHALL be placed in `bootstrap/`
- **AND** booting from the new `.ecec` files SHALL produce a working system

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
