## MODIFIED Requirements

### Requirement: flat serializer emits stack-based build instructions
The `flat-image-serialize` function SHALL remain available for use by the disassembler as an output format renderer. It SHALL no longer be the default serialization path — `ece-save-image` SHALL use binary serialization instead. The function's behavior and output format SHALL remain unchanged.

#### Scenario: Serialize integer
- **WHEN** the image data contains the integer `42`
- **THEN** the serializer SHALL emit the line `int 42`

#### Scenario: Function remains callable
- **WHEN** `flat-image-serialize` is called directly with image data and a stream
- **THEN** it SHALL produce valid text-format output identical to its current behavior
