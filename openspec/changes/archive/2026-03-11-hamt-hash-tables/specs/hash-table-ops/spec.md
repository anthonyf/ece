## MODIFIED Requirements

### Requirement: hash-table constructor function
The `hash-table` function SHALL accept alternating key-value arguments and return a new hash table backed by a HAMT. Arguments SHALL be evaluated (keys need quoting for literal symbols).

#### Scenario: Construct with symbol keys
- **WHEN** `(hash-table 'name "Alice" 'age 30)` is evaluated
- **THEN** it SHALL return a hash table where `(hash-ref result 'name)` is `"Alice"` and `(hash-ref result 'age)` is `30`

#### Scenario: Construct with computed keys
- **WHEN** `(define k 'name)` then `(hash-table k "Alice")` is evaluated
- **THEN** `(hash-ref result 'name)` SHALL be `"Alice"`

#### Scenario: Construct empty hash table
- **WHEN** `(hash-table)` is evaluated
- **THEN** it SHALL return an empty hash table where `(hash-count result)` is `0`

### Requirement: hash-table? predicate
The `hash-table?` function SHALL return `t` for hash table values (HAMT-backed) and `()` for all other values.

#### Scenario: Hash table value
- **WHEN** `(hash-table? (hash-table 'a 1))` is evaluated
- **THEN** it SHALL return `t`

#### Scenario: Non-hash-table value
- **WHEN** `(hash-table? '(1 2 3))` is evaluated
- **THEN** it SHALL return `()`

### Requirement: hash-ref lookup
The `hash-ref` function SHALL look up a key in a HAMT-backed hash table using `equal?` comparison via the hash trie. It SHALL accept an optional default value.

#### Scenario: Key found
- **WHEN** `(hash-ref (hash-table 'name "Alice" 'age 30) 'name)` is evaluated
- **THEN** it SHALL return `"Alice"`

#### Scenario: Key not found without default
- **WHEN** `(hash-ref (hash-table 'name "Alice") 'missing)` is evaluated
- **THEN** it SHALL return `()`

#### Scenario: Key not found with default
- **WHEN** `(hash-ref (hash-table 'name "Alice") 'missing "unknown")` is evaluated
- **THEN** it SHALL return `"unknown"`

#### Scenario: String key lookup
- **WHEN** `(hash-ref (hash-table "first" "Alice") "first")` is evaluated
- **THEN** it SHALL return `"Alice"`

### Requirement: hash-set! mutable update
The `hash-set!` function SHALL mutate a hash table in place by replacing the internal HAMT root. The identity of the hash table wrapper object SHALL be preserved.

#### Scenario: Update existing key
- **WHEN** `(define ht (hash-table 'hp 100))` then `(hash-set! ht 'hp 80)` is evaluated
- **THEN** `(hash-ref ht 'hp)` SHALL return `80`

#### Scenario: Add new key
- **WHEN** `(define ht (hash-table 'hp 100))` then `(hash-set! ht 'mp 50)` is evaluated
- **THEN** `(hash-ref ht 'mp)` SHALL return `50` and `(hash-ref ht 'hp)` SHALL return `100`

#### Scenario: Identity preserved
- **WHEN** a hash table is stored in a variable and mutated with `hash-set!`
- **THEN** the variable SHALL still reference the same object (no re-binding needed)

### Requirement: hash-set functional update
The `hash-set` function SHALL return a new hash table with the key updated or added, using HAMT structural sharing. The original hash table SHALL NOT be modified.

#### Scenario: Functional update
- **WHEN** `(define ht (hash-table 'hp 100))` then `(define ht2 (hash-set ht 'hp 80))` is evaluated
- **THEN** `(hash-ref ht 'hp)` SHALL return `100` and `(hash-ref ht2 'hp)` SHALL return `80`

#### Scenario: Functional add
- **WHEN** `(define ht (hash-table 'hp 100))` then `(define ht2 (hash-set ht 'mp 50))` is evaluated
- **THEN** `(hash-ref ht 'mp)` SHALL return `()` and `(hash-ref ht2 'mp)` SHALL return `50`

### Requirement: hash-remove! mutable removal
The `hash-remove!` function SHALL remove a key-value pair from a hash table in place by replacing the internal HAMT root.

#### Scenario: Remove existing key
- **WHEN** `(define ht (hash-table 'a 1 'b 2))` then `(hash-remove! ht 'a)` is evaluated
- **THEN** `(hash-has-key? ht 'a)` SHALL return `()` and `(hash-has-key? ht 'b)` SHALL return `t`

#### Scenario: Remove non-existent key
- **WHEN** `(hash-remove! (hash-table 'a 1) 'z)` is evaluated
- **THEN** the hash table SHALL be unchanged

### Requirement: hash-has-key? membership test
The `hash-has-key?` function SHALL return `t` if the key exists in the HAMT and `()` otherwise.

#### Scenario: Key exists
- **WHEN** `(hash-has-key? (hash-table 'name "Alice") 'name)` is evaluated
- **THEN** it SHALL return `t`

#### Scenario: Key missing
- **WHEN** `(hash-has-key? (hash-table 'name "Alice") 'age)` is evaluated
- **THEN** it SHALL return `()`

### Requirement: hash-keys list
The `hash-keys` function SHALL return a list of all keys in the hash table by walking the HAMT trie.

#### Scenario: Multiple keys
- **WHEN** `(hash-keys (hash-table 'a 1 'b 2 'c 3))` is evaluated
- **THEN** it SHALL return a list containing `a`, `b`, and `c` (order unspecified)

#### Scenario: Empty hash table
- **WHEN** `(hash-keys (hash-table))` is evaluated
- **THEN** it SHALL return `()`

### Requirement: hash-count size
The `hash-count` function SHALL return the number of key-value pairs in the hash table.

#### Scenario: Non-empty hash table
- **WHEN** `(hash-count (hash-table 'a 1 'b 2 'c 3))` is evaluated
- **THEN** it SHALL return `3`

#### Scenario: Empty hash table
- **WHEN** `(hash-count (hash-table))` is evaluated
- **THEN** it SHALL return `0`

### Requirement: hash-values list
The `hash-values` function SHALL return a list of all values in the hash table by walking the HAMT trie.

#### Scenario: Multiple values
- **WHEN** `(hash-values (hash-table 'a 1 'b 2 'c 3))` is evaluated
- **THEN** it SHALL return a list containing `1`, `2`, and `3` (order unspecified)
