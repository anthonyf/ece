## Requirements

### Requirement: flat serializer emits stack-based build instructions
The `ece-%write-image` function SHALL serialize ECE image data to a flat, line-oriented text format. Each line SHALL contain exactly one opcode with its arguments. The opcodes SHALL be: `int`, `sym`, `kwd`, `str`, `chr`, `nil`, `t`, `cons`, `list`, `vec`, `def`, `ref`.

#### Scenario: Serialize integer
- **WHEN** the image data contains the integer `42`
- **THEN** the serializer SHALL emit the line `int 42`

#### Scenario: Serialize symbol
- **WHEN** the image data contains the symbol `FOO`
- **THEN** the serializer SHALL emit the line `sym FOO`

#### Scenario: Serialize keyword
- **WHEN** the image data contains the keyword `:HASH-TABLE`
- **THEN** the serializer SHALL emit the line `kwd HASH-TABLE`

#### Scenario: Serialize string
- **WHEN** the image data contains the string `hello world`
- **THEN** the serializer SHALL emit the line `str "hello world"`

#### Scenario: Serialize string with escapes
- **WHEN** the image data contains a string with a newline and a double quote
- **THEN** the serializer SHALL emit the line with `\n` for newline and `\"` for double quote

#### Scenario: Serialize character by code point
- **WHEN** the image data contains the character `#\space`
- **THEN** the serializer SHALL emit the line `chr 32`
- **AND** `#\newline` SHALL emit `chr 10`
- **AND** `#\A` SHALL emit `chr 65`

#### Scenario: Serialize nil
- **WHEN** the image data contains NIL
- **THEN** the serializer SHALL emit the line `nil`

#### Scenario: Serialize t
- **WHEN** the image data contains T
- **THEN** the serializer SHALL emit the line `t`

#### Scenario: Serialize cons cell
- **WHEN** the image data contains `(A . B)`
- **THEN** the serializer SHALL emit `sym A`, then `sym B`, then `cons`

#### Scenario: Serialize proper list
- **WHEN** the image data contains the list `(1 2 3)`
- **THEN** the serializer SHALL emit `int 1`, `int 2`, `int 3`, then `list 3`

#### Scenario: Serialize vector
- **WHEN** the image data contains the vector `#(1 2 3)`
- **THEN** the serializer SHALL emit `int 1`, `int 2`, `int 3`, then `vec 3`

### Requirement: flat serializer preserves structural sharing
The serializer SHALL detect structurally shared values (same identity, `eq`) and emit `def N` / `ref N` instructions to preserve sharing.

#### Scenario: Shared cons cell gets def/ref
- **WHEN** the same cons cell appears in two different positions in the image data
- **THEN** the serializer SHALL emit the cell's instructions followed by `def N` at the first occurrence
- **AND** emit `ref N` at subsequent occurrences

#### Scenario: Non-shared values have no def
- **WHEN** a value appears only once in the image data
- **THEN** the serializer SHALL NOT emit a `def` instruction for it

#### Scenario: Reference counting pre-pass
- **WHEN** serialization begins
- **THEN** the serializer SHALL perform a pre-pass to count references to each value (by identity)
- **AND** only values referenced more than once SHALL receive `def` IDs

### Requirement: flat serializer handles the 7-element image structure
The serializer SHALL serialize the complete 7-element image structure (instructions, labels, env, macros, names, params, param-counter) as a single top-level list.

#### Scenario: Full image serialization
- **WHEN** `ece-%write-image` is called with a filename and image data
- **THEN** the output file SHALL contain flat instructions that, when deserialized, reconstruct the exact 7-element image structure
- **AND** the last data instruction in the file SHALL be `list 7`

### Requirement: flat serializer handles gensym keywords
Keywords with non-standard names (e.g., `:|1|` from gensym-based parameter IDs) SHALL be serialized with escaped names using `|...|` delimiters.

#### Scenario: Gensym keyword serialization
- **WHEN** the image data contains the keyword `:|1|`
- **THEN** the serializer SHALL emit `kwd |1|`
- **AND** the deserializer SHALL reconstruct the keyword `:|1|`
