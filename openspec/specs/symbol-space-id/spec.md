## NEW Requirements

### Requirement: space IDs are symbols
Space IDs SHALL be CL symbols interned in the ECE package, not integers.

#### Scenario: Space creation
- **WHEN** `create-space` is called with name `"prelude"`
- **THEN** the space SHALL be registered with key symbol `PRELUDE` in the space registry
- **AND** `get-space 'PRELUDE` SHALL return the space record

### Requirement: space registry is symbol-keyed
The `*space-registry*` SHALL be a hash table with `:test 'eq` keyed by symbols, not a vector indexed by integers.

#### Scenario: Lookup by symbol
- **GIVEN** spaces `prelude`, `compiler`, and `my-game` exist
- **WHEN** `(get-space 'compiler)` is called
- **THEN** the compiler space record SHALL be returned

### Requirement: qualified addresses use symbols
Compiled procedure entries and continuation return addresses SHALL use `(symbol . local-pc)` pairs.

#### Scenario: Make compiled procedure
- **WHEN** a compiled procedure is created in space `prelude`
- **THEN** its entry SHALL be `(prelude . <local-pc>)`

#### Scenario: Capture continuation
- **WHEN** a continuation is captured while executing in space `compiler`
- **THEN** the saved `continue` register SHALL contain `(compiler . <local-pc>)`

### Requirement: cross-space jump by symbol
The executor SHALL switch spaces by looking up the target symbol in the space registry.

#### Scenario: Cross-space return
- **WHEN** `(goto (reg continue))` is executed with continue = `(prelude . 4523)`
- **AND** the current space is `compiler`
- **THEN** the executor SHALL switch to the `prelude` space and jump to PC 4523
- **AND** the switch SHALL use `eq` symbol comparison (O(1))
