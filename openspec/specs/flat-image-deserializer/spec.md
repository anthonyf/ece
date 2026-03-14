## Requirements

### Requirement: flat deserializer loads image from line-oriented format
The `ece-load-image` function SHALL read a flat-format image file and restore all global state. It SHALL process the file line by line, using a stack to build compound data structures.

#### Scenario: Deserialize integers
- **WHEN** the deserializer reads the line `int 42`
- **THEN** the integer `42` SHALL be pushed onto the build stack

#### Scenario: Deserialize negative integers
- **WHEN** the deserializer reads the line `int -7`
- **THEN** the integer `-7` SHALL be pushed onto the build stack

#### Scenario: Deserialize symbols
- **WHEN** the deserializer reads the line `sym FOO`
- **THEN** the symbol `ECE::FOO` SHALL be pushed onto the build stack (interned in the ECE package)

#### Scenario: Deserialize keywords
- **WHEN** the deserializer reads the line `kwd HASH-TABLE`
- **THEN** the keyword `:HASH-TABLE` SHALL be pushed onto the build stack

#### Scenario: Deserialize escaped keywords
- **WHEN** the deserializer reads the line `kwd |1|`
- **THEN** the keyword `:|1|` SHALL be pushed onto the build stack

#### Scenario: Deserialize strings
- **WHEN** the deserializer reads the line `str "hello world"`
- **THEN** the string `"hello world"` SHALL be pushed onto the build stack

#### Scenario: Deserialize strings with escapes
- **WHEN** the deserializer reads the line `str "line1\nline2"`
- **THEN** a string containing a literal newline between "line1" and "line2" SHALL be pushed

#### Scenario: Deserialize characters
- **WHEN** the deserializer reads the line `chr 32`
- **THEN** the character `#\space` (code point 32) SHALL be pushed onto the build stack

#### Scenario: Deserialize nil
- **WHEN** the deserializer reads the line `nil`
- **THEN** NIL SHALL be pushed onto the build stack

#### Scenario: Deserialize t
- **WHEN** the deserializer reads the line `t`
- **THEN** T SHALL be pushed onto the build stack

#### Scenario: Deserialize cons
- **WHEN** the stack contains values A (second from top) and B (top)
- **AND** the deserializer reads the line `cons`
- **THEN** it SHALL pop B and A, push `(A . B)`

#### Scenario: Deserialize list
- **WHEN** the stack contains values V1, V2, V3 (V1 deepest)
- **AND** the deserializer reads the line `list 3`
- **THEN** it SHALL pop 3 values and push the proper list `(V1 V2 V3)`

#### Scenario: Deserialize vector
- **WHEN** the stack contains values V1, V2, V3 (V1 deepest)
- **AND** the deserializer reads the line `vec 3`
- **THEN** it SHALL pop 3 values and push the vector `#(V1 V2 V3)`

### Requirement: flat deserializer restores structural sharing
The deserializer SHALL support `def N` and `ref N` instructions to restore structural sharing.

#### Scenario: Define and reference shared value
- **WHEN** the deserializer reads `def 0` after building a cons cell
- **THEN** it SHALL assign ID 0 to the top-of-stack value without popping it
- **AND** when `ref 0` is later read, it SHALL push the same (eq) value onto the stack

#### Scenario: Multiple references to same value
- **WHEN** a value is defined with `def 5` and referenced three times with `ref 5`
- **THEN** all four occurrences SHALL be `eq` to each other

### Requirement: flat deserializer restores global state
After reading the flat-format file, the deserializer SHALL destructure the top-of-stack value as a 7-element list and restore all global state identically to the current `ece-load-image`. Environment frames that are vectors SHALL be restored as vectors.

#### Scenario: Full image load restores system state
- **WHEN** `ece-load-image` is called with a flat-format image file
- **THEN** `*global-instruction-source*` SHALL be rebuilt from the instruction list
- **AND** `*global-instruction-vector*` SHALL be rebuilt with resolved operations
- **AND** `*global-label-table*` SHALL be restored
- **AND** `*global-env*` SHALL be restored
- **AND** `*compile-time-macros*` SHALL be restored
- **AND** `*procedure-name-table*` SHALL be restored
- **AND** `*parameter-table*` and `*parameter-counter*` SHALL be restored

#### Scenario: Full image load restores system state with vector frames
- **WHEN** `ece-load-image` is called with an image containing vector-backed lexical frames
- **THEN** `*global-env*` SHALL be restored with vector frames intact
- **AND** `lexical-ref` operations SHALL work correctly on the restored environment
- **AND** all prelude functions, macros, and primitives SHALL work correctly

#### Scenario: Image load is idempotent with save
- **WHEN** an image is saved with `ece-%write-image` and loaded with `ece-load-image`
- **THEN** the restored system state SHALL be functionally equivalent to the state at save time
- **AND** all prelude functions, macros, and primitives SHALL work correctly

#### Scenario: Image round-trip preserves frame types
- **WHEN** an image is saved and then loaded
- **THEN** lexical frames SHALL remain as vectors
- **AND** the global frame SHALL remain as a list-based frame

### Requirement: flat deserializer requires no recursive parser
The deserializer SHALL be implementable as a simple loop with a switch/case over opcode strings. It SHALL NOT require recursive descent parsing, parenthesis matching, or lookahead beyond the current line.

#### Scenario: Linear processing
- **WHEN** the deserializer processes a flat-format image
- **THEN** each line SHALL be processed independently in a single forward pass
- **AND** no backtracking or lookahead SHALL be required
