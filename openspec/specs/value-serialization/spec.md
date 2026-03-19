## NEW Requirements

### Requirement: serialize-value produces tagged s-expressions
`serialize-value` SHALL convert any ECE value to a string of s-expressions that the ECE reader can parse back.

#### Scenario: Plain values round-trip
- **WHEN** `serialize-value` is called with `42`, `"hello"`, `#t`, `#f`, `'foo`, or `#\a`
- **THEN** the output SHALL be readable by the ECE reader
- **AND** the deserialized value SHALL be `equal?` to the original

#### Scenario: List and pair round-trip
- **WHEN** `serialize-value` is called with `(1 2 3)` or `(a . b)`
- **THEN** the output SHALL reconstruct the same structure on deserialization

### Requirement: compiled procedures serialize with space-qualified addresses
Compiled procedure entries `(symbol . local-pc)` SHALL serialize preserving the space symbol.

#### Scenario: Compiled procedure round-trip
- **GIVEN** a compiled procedure with entry `(prelude . 4523)`
- **WHEN** serialized and deserialized
- **THEN** the entry SHALL be `(prelude . 4523)`
- **AND** the environment SHALL be reconstructed

### Requirement: primitives serialize by name
Primitive values `(primitive <id>)` SHALL serialize as `(#:primitive <name>)` using the symbol name, not the numeric ID.

#### Scenario: Primitive round-trip
- **WHEN** a primitive `(primitive 22)` (which is `=`) is serialized
- **THEN** the output SHALL contain the name `=`, not the ID `22`
- **AND** deserialization SHALL look up the current ID for `=`

### Requirement: hash tables serialize as key-value pairs
HAMT hash tables SHALL serialize as `(#:hash-table (k1 v1) (k2 v2) ...)`.

#### Scenario: Hash table round-trip
- **GIVEN** a hash table `{name "Alice" age 30}`
- **WHEN** serialized and deserialized
- **THEN** `(hash-ref result 'name)` SHALL return `"Alice"`
- **AND** `(hash-ref result 'age)` SHALL return `30`

### Requirement: continuations serialize with space-qualified addresses
Continuations SHALL serialize preserving the stack, continue register, and all space-qualified addresses within.

#### Scenario: Continuation round-trip
- **GIVEN** a continuation captured with `call/cc`
- **WHEN** serialized and deserialized
- **THEN** invoking the deserialized continuation SHALL resume at the correct point

### Requirement: shared structure preserved
Values that share substructure SHALL use a ref/def mechanism to avoid duplication and handle cycles.

#### Scenario: Shared list
- **GIVEN** a value where two fields reference the same list object
- **WHEN** serialized and deserialized
- **THEN** the shared structure SHALL be preserved (both fields `eq?` to the same object)

### Requirement: global environment sentinel
When a closure's environment chain includes the global environment frame, it SHALL serialize as a sentinel rather than serializing the entire global environment.

#### Scenario: Global env in closure
- **GIVEN** a top-level function whose closure captures `*global-env*`
- **WHEN** serialized and deserialized
- **THEN** the closure's environment SHALL reconnect to the current `*global-env*`
