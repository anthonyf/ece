## ADDED Requirements

### Requirement: Core primitive IDs for hash table operations
The `primitives.def` manifest SHALL include core primitive IDs (range 0-99) for all hash table operations. Each host runtime SHALL implement these primitives natively.

#### Scenario: Primitives registered at boot
- **WHEN** the runtime boots
- **THEN** `%make-hash-table`, `hash-table?`, `hash-ref`, `hash-set!`, `hash-remove!`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count` SHALL all be available as primitives

### Requirement: %make-hash-table creates an empty mutable hash table
The `%make-hash-table` primitive SHALL return a new empty mutable hash table.

#### Scenario: Create empty table
- **WHEN** `(%make-hash-table)` is called
- **THEN** it SHALL return a hash table with `(hash-count ht)` = 0

### Requirement: hash-ref looks up a key using eq? equality
The `hash-ref` primitive SHALL look up a key in a hash table using `eq?` semantics. If not found, it SHALL return `#f` or an optional default value.

#### Scenario: Key found
- **WHEN** `(hash-ref ht 'x)` is called and `'x` was previously set
- **THEN** it SHALL return the associated value

#### Scenario: Key not found without default
- **WHEN** `(hash-ref ht 'missing)` is called and `'missing` was never set
- **THEN** it SHALL return `#f`

#### Scenario: Key not found with default
- **WHEN** `(hash-ref ht 'missing 42)` is called and `'missing` was never set
- **THEN** it SHALL return `42`

### Requirement: hash-set! mutates a hash table
The `hash-set!` primitive SHALL add or update a key-value pair in the hash table.

#### Scenario: Set new key
- **WHEN** `(hash-set! ht 'x 10)` is called
- **THEN** `(hash-ref ht 'x)` SHALL return `10`

#### Scenario: Update existing key
- **WHEN** `(hash-set! ht 'x 10)` then `(hash-set! ht 'x 20)` is called
- **THEN** `(hash-ref ht 'x)` SHALL return `20`

### Requirement: hash-remove! removes a key
The `hash-remove!` primitive SHALL remove a key-value pair from the hash table.

#### Scenario: Remove existing key
- **WHEN** `(hash-set! ht 'x 10)` then `(hash-remove! ht 'x)` is called
- **THEN** `(hash-has-key? ht 'x)` SHALL return `#f`

### Requirement: hash-has-key? tests for key presence
The `hash-has-key?` primitive SHALL return `#t` if the key exists, `#f` otherwise.

#### Scenario: Key exists
- **WHEN** `(hash-set! ht 'x 10)` was called
- **THEN** `(hash-has-key? ht 'x)` SHALL return `#t`

### Requirement: hash-keys and hash-values return lists
The `hash-keys` primitive SHALL return a list of all keys. The `hash-values` primitive SHALL return a list of all values.

#### Scenario: Keys and values of populated table
- **WHEN** a hash table has entries `{a: 1, b: 2}`
- **THEN** `(hash-keys ht)` SHALL return a list containing `a` and `b`
- **AND** `(hash-values ht)` SHALL return a list containing `1` and `2`

### Requirement: hash-count returns entry count
The `hash-count` primitive SHALL return the number of key-value pairs.

#### Scenario: Count after mutations
- **WHEN** `(hash-set! ht 'a 1)` and `(hash-set! ht 'b 2)` are called
- **THEN** `(hash-count ht)` SHALL return `2`

### Requirement: hash-table? type predicate
The `hash-table?` primitive SHALL return `#t` for hash tables and `#f` for all other values.

#### Scenario: Hash table is recognized
- **WHEN** `(hash-table? (%make-hash-table))` is called
- **THEN** it SHALL return `#t`

#### Scenario: Non-hash-table is rejected
- **WHEN** `(hash-table? 42)` is called
- **THEN** it SHALL return `#f`
