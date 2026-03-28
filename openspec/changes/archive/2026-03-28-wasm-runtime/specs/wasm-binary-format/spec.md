## ADDED Requirements

### Requirement: Binary .ececb file format
The build system SHALL define a binary `.ececb` format that encodes compiled ECE instructions for efficient loading by the WASM runtime. The format SHALL be produced by a converter tool written in ECE.

#### Scenario: File header
- **WHEN** a `.ececb` file is read
- **THEN** it SHALL begin with the magic bytes `ECEB`, followed by a version byte, the space name (length-prefixed UTF-8), and a macro count

#### Scenario: Instruction encoding
- **WHEN** the converter processes an instruction like `(assign val (const 42))`
- **THEN** it SHALL emit a compact binary encoding: opcode byte, followed by operand type bytes and values

#### Scenario: Label encoding
- **WHEN** the converter encounters a label like `mc-entry-37341`
- **THEN** it SHALL encode the label name and its PC offset in the label table section

#### Scenario: Constant encoding — fixnums
- **WHEN** a constant operand is an integer
- **THEN** it SHALL be encoded as a type tag byte followed by a 32-bit signed integer

#### Scenario: Constant encoding — strings
- **WHEN** a constant operand is a string
- **THEN** it SHALL be encoded as a type tag byte, length (u32), and UTF-8 bytes

#### Scenario: Constant encoding — symbols
- **WHEN** a constant operand is a symbol
- **THEN** it SHALL be encoded as a type tag byte, length (u16), and the symbol name in UTF-8 bytes

#### Scenario: Constant encoding — special values
- **WHEN** a constant operand is #t, #f, '(), or eof
- **THEN** it SHALL be encoded as a single type tag byte identifying the special value

### Requirement: Converter tool written in ECE
The `.ecec` to `.ececb` converter SHALL be written in ECE (as a `.scm` file) and run on the CL host during the build process.

#### Scenario: Convert a .ecec file
- **WHEN** the converter is invoked with a `.ecec` file path
- **THEN** it SHALL read the s-expression instructions, encode them in binary, and write a `.ececb` file

#### Scenario: Round-trip fidelity
- **WHEN** a `.ecec` file is converted to `.ececb` and loaded by the WASM runtime
- **THEN** the resulting instruction vector and label table SHALL be semantically identical to what the CL runtime produces from the same `.ecec` file

### Requirement: Build integration
The `make bootstrap` target SHALL produce `.ececb` files alongside existing `.ecec` files.

#### Scenario: Make bootstrap produces both formats
- **WHEN** `make bootstrap` is run
- **THEN** for each `.ecec` file in `bootstrap/`, a corresponding `.ececb` file SHALL exist

### Requirement: write-byte primitive
A new `write-byte` primitive SHALL be added to enable the ECE converter tool to emit binary output.

#### Scenario: Write a single byte
- **WHEN** `write-byte` is called with an integer 0-255 and an output port
- **THEN** it SHALL write that byte to the port without any encoding transformation
