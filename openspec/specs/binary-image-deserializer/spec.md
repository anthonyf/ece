## ADDED Requirements

### Requirement: binary deserializer loads image in a single pass
The `binary-image-deserialize` function SHALL read a binary image file and restore all global state. It SHALL build resolved instruction forms (with `op-fn` and function pointers) directly during deserialization, without a separate `resolve-operations` pass.

#### Scenario: Deserialize header and validate
- **WHEN** a binary image file is opened
- **THEN** the deserializer SHALL read the 12-byte header
- **AND** SHALL verify the magic bytes are "ECE"
- **AND** SHALL verify the version is supported
- **AND** SHALL signal an error if validation fails

#### Scenario: Rebuild symbol table
- **WHEN** the header indicates N symbols
- **THEN** the deserializer SHALL read N symbol entries and intern them into the appropriate CL packages
- **AND** subsequent symbol references by index SHALL resolve to the interned symbols

#### Scenario: Deserialize instructions with resolved operations
- **WHEN** the instruction section contains an assign instruction with op source
- **THEN** the deserializer SHALL build `(assign <reg> (op-fn #'<function>) <operands>...)` directly
- **AND** SHALL NOT build an intermediate `(op <name>)` form

#### Scenario: Deserialize instructions for source vector
- **WHEN** loading instructions
- **THEN** the deserializer SHALL populate both `*global-instruction-vector*` (resolved) and `*global-instruction-source*` (unresolved `(op name)` form)
- **AND** the source vector SHALL contain the symbolic form for later serialization

#### Scenario: Restore all global state
- **WHEN** a binary image is fully deserialized
- **THEN** `*global-instruction-vector*`, `*global-instruction-source*`, `*global-label-table*`, `*global-env*`, `*compile-time-macros*`, `*procedure-name-table*`, `*parameter-table*`, and `*parameter-counter*` SHALL all be restored

#### Scenario: Data section round-trip fidelity
- **WHEN** a binary image is loaded that was saved with integers, strings, symbols, lists, vectors, characters, booleans, keywords, and gensyms in the environment
- **THEN** all values SHALL be restored with identical type and value

### Requirement: binary deserializer is significantly faster than text
The binary deserializer SHALL load images significantly faster than `flat-image-deserialize` for the same data.

#### Scenario: Bootstrap image load time
- **WHEN** the bootstrap image is loaded in binary format
- **THEN** the load time SHALL be at least 3x faster than loading the equivalent text format image

### Requirement: format auto-detection
The `ece-load-image` function SHALL auto-detect whether a file is binary or text format by checking the first 3 bytes for the "ECE" magic.

#### Scenario: Load binary image
- **WHEN** `ece-load-image` is called with a binary format file
- **THEN** it SHALL use the binary deserializer

#### Scenario: Load legacy text image
- **WHEN** `ece-load-image` is called with a text format file (no "ECE" magic)
- **THEN** it SHALL fall back to `flat-image-deserialize`
