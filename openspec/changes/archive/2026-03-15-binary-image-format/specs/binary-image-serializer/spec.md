## ADDED Requirements

### Requirement: binary serializer writes compact binary image format
The `binary-image-serialize` function SHALL write ECE image data to a binary format consisting of: a header, a symbol table, a section directory, and typed sections. The output SHALL be a byte stream suitable for `write-sequence`.

#### Scenario: Header format
- **WHEN** a binary image is serialized
- **THEN** the first 3 bytes SHALL be the ASCII string "ECE"
- **AND** byte 4 SHALL be the format version (initially 1)
- **AND** bytes 5-8 SHALL be a big-endian u32 symbol count
- **AND** bytes 9-12 SHALL be a big-endian u32 section count

#### Scenario: Symbol table deduplication
- **WHEN** the image data contains multiple references to the same symbol (e.g., `ASSIGN` appearing 10,000+ times)
- **THEN** the symbol table SHALL contain exactly one entry for that symbol
- **AND** all references in the instruction and data sections SHALL use the symbol's u16 index

#### Scenario: Symbol table entries include package info
- **WHEN** a symbol is interned in the `:ece` package
- **THEN** its entry SHALL use package-tag 0
- **WHEN** a symbol is a keyword
- **THEN** its entry SHALL use package-tag 1
- **WHEN** a symbol is in the `:cl` package
- **THEN** its entry SHALL use package-tag 2
- **WHEN** a symbol is uninterned (gensym)
- **THEN** its entry SHALL use package-tag 3
- **WHEN** a symbol is in another package
- **THEN** its entry SHALL use package-tag 4 followed by a length-prefixed package name

### Requirement: instruction section uses typed binary encoding
The instruction section SHALL encode register machine instructions using typed opcodes rather than generic cons-tree serialization. Each instruction SHALL begin with a 1-byte instruction opcode, followed by type-specific operands.

#### Scenario: Encode assign with op source
- **WHEN** serializing `(assign env (op compiled-procedure-env) (reg proc))`
- **THEN** the output SHALL be: assign-opcode(1B), register-env(1B), source-type-op(1B), operation-compiled-procedure-env(1B), operand-count(1B), operand-type-reg(1B), register-proc(1B)

#### Scenario: Encode assign with const source
- **WHEN** serializing `(assign val (const 42))`
- **THEN** the output SHALL be: assign-opcode(1B), register-val(1B), source-type-const(1B), followed by the value `42` in data encoding

#### Scenario: Encode assign with reg source
- **WHEN** serializing `(assign proc (reg val))`
- **THEN** the output SHALL be: assign-opcode(1B), register-proc(1B), source-type-reg(1B), register-val(1B)

#### Scenario: Encode assign with label source
- **WHEN** serializing `(assign continue (label entry42))`
- **THEN** the output SHALL be: assign-opcode(1B), register-continue(1B), source-type-label(1B), followed by the symbol in data encoding

#### Scenario: Encode save/restore
- **WHEN** serializing `(save continue)` or `(restore env)`
- **THEN** the output SHALL be: save/restore-opcode(1B), register(1B)

#### Scenario: Encode test
- **WHEN** serializing `(test (op false?) (reg val))`
- **THEN** the output SHALL be: test-opcode(1B), operation-false?(1B), operand-count(1B), operand-type-reg(1B), register-val(1B)

#### Scenario: Encode goto with label
- **WHEN** serializing `(goto (label after-call-5))`
- **THEN** the output SHALL be: goto-opcode(1B), target-type-label(1B), followed by the label symbol in data encoding

#### Scenario: Encode goto with register
- **WHEN** serializing `(goto (reg continue))`
- **THEN** the output SHALL be: goto-opcode(1B), target-type-reg(1B), register-continue(1B)

#### Scenario: Encode branch
- **WHEN** serializing `(branch (label false-branch-7))`
- **THEN** the output SHALL be: branch-opcode(1B), followed by the label symbol in data encoding

### Requirement: data section uses binary stack-machine encoding
Non-instruction sections (environment, macros, parameters, labels, procedure names, parameter counter) SHALL be encoded using a binary version of the stack-machine format with single-byte type tags and binary values.

#### Scenario: Encode integer
- **WHEN** the data contains integer `42`
- **THEN** the output SHALL be: int-tag(1B), value as big-endian i64(8B)

#### Scenario: Encode symbol by table index
- **WHEN** the data contains a symbol that is at index 5 in the symbol table
- **THEN** the output SHALL be: sym-tag(1B), index as big-endian u16(2B)

#### Scenario: Encode string
- **WHEN** the data contains the string `"hello"`
- **THEN** the output SHALL be: str-tag(1B), length as big-endian u32(4B), UTF-8 bytes

#### Scenario: Encode list
- **WHEN** the data contains the list `(1 2 3)`
- **THEN** the serializer SHALL emit encoding for 1, 2, 3, then list-tag(1B) with count as big-endian u16(2B)

#### Scenario: Encode shared references
- **WHEN** a value is referenced multiple times in the data
- **THEN** the first occurrence SHALL be followed by def-tag(1B) + id(u16)
- **AND** subsequent occurrences SHALL be ref-tag(1B) + id(u16)

### Requirement: binary image is smaller than text format
The binary serializer SHALL produce images significantly smaller than the text format for the same data.

#### Scenario: Bootstrap image size reduction
- **WHEN** the bootstrap image is serialized in binary format
- **THEN** the resulting file SHALL be less than 50% the size of the text format equivalent
