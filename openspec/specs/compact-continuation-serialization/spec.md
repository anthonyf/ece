## NEW Requirements

### Requirement: serialized continuations exclude code objects
Serialized continuations SHALL NOT contain instruction vectors, label tables, resolved instruction arrays, or source expression lists. Only data (values, environments, addresses) SHALL be serialized.

#### Scenario: Simple continuation size
- **GIVEN** a program that captures a continuation with `call/cc` at a point with no user-defined local variables
- **WHEN** the continuation is serialized with `serialize-value`
- **THEN** the serialized string length SHALL be less than 500 bytes

#### Scenario: Continuation with game state
- **GIVEN** a program that captures a continuation with a hash table of 10 key-value pairs in scope
- **WHEN** the continuation is serialized
- **THEN** the serialized size SHALL be proportional to the game state data, not to the instruction vector size

### Requirement: code objects replaced with skip sentinels
When the serializer encounters a code-like object (instruction vector, resolved instruction array, label table contents), it SHALL emit a sentinel `(%ser/code-skip)` and stop recursing into that subtree.

#### Scenario: Instruction vector encountered
- **WHEN** the serializer encounters a CL vector containing instruction lists
- **THEN** it SHALL emit `(%ser/code-skip)` instead of serializing the vector contents

### Requirement: deserialization handles skip sentinels
When the deserializer encounters `(%ser/code-skip)`, it SHALL replace it with an empty placeholder (e.g., `#f` or `'()`), since code objects are loaded from `.ecec` files at boot.

#### Scenario: Load continuation with code-skip
- **GIVEN** a serialized continuation containing `(%ser/code-skip)` sentinels
- **WHEN** deserialized with `deserialize-value`
- **THEN** the continuation SHALL be usable — invoking it SHALL resume execution correctly since the code is already in memory
