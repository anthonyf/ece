## ADDED Requirements

### Requirement: disassembler converts binary images to human-readable text
The `ece-disassemble-image` function SHALL read a binary image file and produce a human-readable text representation showing reconstituted register machine instructions, labels, environment bindings, and metadata.

#### Scenario: Disassemble instruction section
- **WHEN** a binary image is disassembled
- **THEN** each instruction SHALL be displayed as a symbolic register machine instruction
- **AND** the output SHALL include a PC number prefix for each instruction
- **AND** instructions SHALL be displayed in forms like `(assign env (op compiled-procedure-env) (reg proc))`

#### Scenario: Disassemble with header summary
- **WHEN** a binary image is disassembled
- **THEN** the output SHALL begin with a header showing image version, instruction count, symbol count, and shared object count

#### Scenario: Disassemble label table
- **WHEN** the image contains labels
- **THEN** the output SHALL include a labels section mapping label names to PC addresses

#### Scenario: Disassemble environment bindings
- **WHEN** the image contains environment bindings
- **THEN** the output SHALL include an environment section showing binding names and value summaries (e.g., `<primitive>`, `<compiled-procedure @PC>`, literal values)

#### Scenario: Output to stream
- **WHEN** `ece-disassemble-image` is called with an optional output stream argument
- **THEN** the output SHALL be written to that stream
- **WHEN** no output stream is provided
- **THEN** the output SHALL be written to `*standard-output*`

### Requirement: disassembler is accessible from Make
A `make disasm` target SHALL invoke the disassembler on the bootstrap image and print the output.

#### Scenario: Make disasm target
- **WHEN** `make disasm` is executed
- **THEN** the bootstrap image SHALL be disassembled to stdout
