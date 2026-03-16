## MODIFIED Requirements

### Requirement: binary deserializer loads image in a single pass
The `binary-image-deserialize` function SHALL read a binary image file and restore all global state. It SHALL build resolved instruction forms (with `op-fn` and function pointers) directly during deserialization, without a separate `resolve-operations` pass. It SHALL reconstruct hash-table frames from serialized data.

#### Scenario: Deserialize hash-table frame
- **WHEN** the environment data section contains a hash-table frame encoding
- **THEN** the deserializer SHALL create a `(:hash-frame . <hash-table>)` frame
- **AND** SHALL populate the hash-table with all key-value pairs from the serialized entries

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

#### Scenario: Restore all global state
- **WHEN** a binary image is fully deserialized
- **THEN** `*global-instruction-vector*`, `*global-instruction-source*`, `*global-label-table*`, `*global-env*`, `*compile-time-macros*`, `*procedure-name-table*`, `*parameter-table*`, and `*parameter-counter*` SHALL all be restored
- **AND** `*global-env*` SHALL contain a hash-table frame for the global bindings
