## ADDED Requirements

### Requirement: Symbol intern table
The WASM runtime SHALL maintain a symbol intern table that maps symbol name strings to unique integer IDs. Two symbols with the same name SHALL always have the same ID.

#### Scenario: Intern new symbol
- **WHEN** a symbol name is interned for the first time
- **THEN** a new unique integer ID SHALL be assigned and a `$symbol` struct created

#### Scenario: Intern existing symbol
- **WHEN** a symbol name that has already been interned is requested
- **THEN** the same `$symbol` struct (same ID) SHALL be returned

### Requirement: Symbol equality by ID
Symbol equality (`eq?` on symbols) SHALL compare integer IDs, not string names.

#### Scenario: Same symbol is eq
- **WHEN** `eq?` is called on two references to the symbol `foo`
- **THEN** the result SHALL be true (same ID)

#### Scenario: Different symbols are not eq
- **WHEN** `eq?` is called on symbols `foo` and `bar`
- **THEN** the result SHALL be false (different IDs)

### Requirement: symbol->string operation
The `symbol->string` primitive SHALL return the name string of a symbol.

#### Scenario: Get symbol name
- **WHEN** `symbol->string` is called on the symbol `hello`
- **THEN** it SHALL return the string `"hello"`

### Requirement: string->symbol operation
The `string->symbol` primitive SHALL intern a string as a symbol.

#### Scenario: Intern from string
- **WHEN** `string->symbol` is called with `"world"`
- **THEN** it SHALL return the interned symbol `world`

### Requirement: Pre-intern bootstrap symbols
The runtime SHALL pre-intern all symbols referenced by primitives and the initial environment at startup, before executing any `.ececb` code.

#### Scenario: Primitive symbols available at boot
- **WHEN** the WASM runtime starts and loads the global environment
- **THEN** all primitive names from `primitives.def` SHALL already be interned in the symbol table
