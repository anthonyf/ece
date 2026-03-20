## MODIFIED Requirements

### Requirement: hash-table constructor uses platform primitives
The `(hash-table key val ...)` constructor SHALL create a platform-native hash table by calling `%make-hash-table` and `hash-set!`, rather than constructing a HAMT.

#### Scenario: Create hash table with literal syntax
- **WHEN** `(hash-table 'a 1 'b 2)` is evaluated
- **THEN** it SHALL return a platform-native hash table where `(hash-ref ht 'a)` = `1` and `(hash-ref ht 'b)` = `2`

#### Scenario: hash-table? recognizes platform tables
- **WHEN** `(hash-table? (hash-table 'a 1))` is evaluated
- **THEN** it SHALL return `#t`
