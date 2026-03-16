## MODIFIED Requirements

### Requirement: data section uses binary stack-machine encoding
Non-instruction sections (environment, macros, parameters, labels, procedure names, parameter counter) SHALL be encoded using a binary version of the stack-machine format with single-byte type tags and binary values. The data section SHALL additionally support hash-table frame encoding using a dedicated type tag.

#### Scenario: Encode hash-table frame
- **WHEN** the environment data contains a hash-table frame `(:hash-frame . <hash-table>)`
- **THEN** the serializer SHALL emit a hash-frame type tag followed by the entry count as big-endian u16, then each entry as a key-value pair (symbol encoding followed by value encoding) in stack-machine order
- **AND** the frame SHALL participate in the def/ref shared-reference mechanism

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
