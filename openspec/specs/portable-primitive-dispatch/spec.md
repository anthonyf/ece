## MODIFIED Requirements

### Requirement: primitive representation uses numeric IDs
Primitives SHALL be represented as `(primitive <id>)` where `<id>` is the numeric ID from the manifest, replacing the current `(primitive <cl-symbol>)` representation.

#### Scenario: primitive stored with numeric ID
- **WHEN** `+` is looked up in `*global-env*`
- **THEN** the result SHALL be `(primitive 0)` (assuming `+` has ID 0 in the manifest)

### Requirement: dispatch table
Each runtime SHALL maintain a dispatch table (array indexed by primitive ID) mapping IDs to native callable functions.

#### Scenario: CL dispatch table
- **WHEN** the CL runtime starts
- **THEN** `*primitive-dispatch-table*` SHALL be an array where index 0 contains the CL function for `+`, index 1 for `-`, etc.

#### Scenario: dispatch table lookup
- **WHEN** `apply-primitive-procedure` is called with `(primitive 0)` and args `(3 4)`
- **THEN** it SHALL look up index 0 in the dispatch table, call the function with args `(3 4)`, and return `7`

### Requirement: unsupported primitive stubs
When a runtime does not support a primitive ID (e.g., CL runtime encounters a browser-only primitive), the dispatch table entry SHALL contain a stub function that signals an error with a message identifying the primitive name and required platform.

#### Scenario: CL encounters browser primitive
- **WHEN** `apply-primitive-procedure` is called with `(primitive 200)` (a browser-only primitive)
- **THEN** it SHALL signal an error like "Primitive %create-element requires browser platform"

### Requirement: apply-primitive-procedure uses table lookup
`apply-primitive-procedure` SHALL dispatch via array index lookup instead of `symbol-function`.

#### Scenario: performance equivalence
- **WHEN** a primitive is called
- **THEN** dispatch SHALL be O(1) via array indexing

## MODIFIED Requirements (Image Format)

### Requirement: image serialization stores numeric IDs
The binary image serializer SHALL write primitives as `PRIM_TAG` followed by a uint16 primitive ID, replacing the current symbol-based serialization.

#### Scenario: serialize primitive
- **WHEN** `(primitive 14)` is serialized to binary
- **THEN** the output SHALL be the PRIM_TAG byte followed by the two bytes encoding 14

### Requirement: image deserialization resolves IDs
The binary image deserializer SHALL read the uint16 ID and construct `(primitive <id>)`, looking up the dispatch table to verify the primitive is available.

#### Scenario: deserialize known primitive
- **WHEN** binary data contains PRIM_TAG followed by uint16 value 14
- **THEN** deserialization SHALL produce `(primitive 14)`

#### Scenario: deserialize unknown primitive
- **WHEN** binary data contains PRIM_TAG followed by an ID not in the dispatch table
- **THEN** deserialization SHALL produce a stub primitive that errors on invocation
