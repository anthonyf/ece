## Requirements

### Requirement: hash-code computes 32-bit hash for any ECE value
The `hash-code` function SHALL accept any ECE value and return a non-negative 32-bit integer. Values that are `equal?` SHALL produce the same hash code.

#### Scenario: Number hashing
- **WHEN** `(hash-code 42)` is evaluated
- **THEN** the result SHALL be a non-negative integer less than 4294967296

#### Scenario: Symbol hashing
- **WHEN** `(hash-code 'hello)` is evaluated
- **THEN** the result SHALL be a non-negative integer less than 4294967296

#### Scenario: String hashing
- **WHEN** `(hash-code "hello")` is evaluated
- **THEN** the result SHALL be a non-negative integer less than 4294967296

#### Scenario: Equal values produce equal hashes
- **WHEN** `(= (hash-code "abc") (hash-code "abc"))` is evaluated
- **THEN** the result SHALL be `t`

#### Scenario: Nil hashing
- **WHEN** `(hash-code ())` is evaluated
- **THEN** the result SHALL be `0`

#### Scenario: Pair hashing
- **WHEN** `(hash-code (cons 1 2))` is evaluated
- **THEN** the result SHALL be a non-negative integer less than 4294967296

#### Scenario: Equal pairs produce equal hashes
- **WHEN** `(= (hash-code (list 1 2 3)) (hash-code (list 1 2 3)))` is evaluated
- **THEN** the result SHALL be `t`

### Requirement: popcount counts set bits in an integer
The `popcount` function SHALL return the number of 1-bits in the binary representation of a non-negative integer.

#### Scenario: Zero
- **WHEN** `(popcount 0)` is evaluated
- **THEN** the result SHALL be `0`

#### Scenario: All bits set in a byte
- **WHEN** `(popcount 255)` is evaluated
- **THEN** the result SHALL be `8`

#### Scenario: Single bit
- **WHEN** `(popcount 16)` is evaluated
- **THEN** the result SHALL be `1`

#### Scenario: Mixed bits
- **WHEN** `(popcount 42)` is evaluated (binary 101010)
- **THEN** the result SHALL be `3`

### Requirement: HAMT node representation
A HAMT node SHALL be represented as `(:hamt-node bitmap entries-vector)` where bitmap is a 32-bit integer indicating occupied slots and entries-vector is a vector containing only the occupied entries (compact representation). Each entry SHALL be either a key-value pair `(key . val)`, another HAMT node, or a collision node.

#### Scenario: Single-entry node
- **WHEN** a HAMT node has one entry at logical slot 5
- **THEN** the bitmap SHALL be `32` (bit 5 set) and the entries-vector SHALL have length 1

#### Scenario: Multiple-entry node
- **WHEN** a HAMT node has entries at logical slots 2, 5, and 17
- **THEN** the bitmap SHALL have bits 2, 5, and 17 set, and the entries-vector SHALL have length 3

### Requirement: HAMT collision node for full hash collisions
When two keys produce identical 32-bit hash codes, they SHALL be stored in a collision node `(:hamt-collision entries-alist)` where entries-alist is a list of `(key . val)` pairs. Lookup in a collision node SHALL use `equal?` comparison.

#### Scenario: Two keys with same hash
- **WHEN** two keys that happen to produce the same 32-bit hash are inserted
- **THEN** both SHALL be retrievable via `hash-ref` using `equal?` comparison

### Requirement: HAMT lookup follows hash bits through trie levels
HAMT lookup SHALL extract 5 bits of the hash code at each trie level (bits 0-4 at level 0, bits 5-9 at level 1, etc.), use the extracted index to check the bitmap, and if present, follow the corresponding entry in the compact vector.

#### Scenario: Lookup existing key
- **WHEN** a key is looked up in a HAMT that contains it
- **THEN** the correct value SHALL be returned

#### Scenario: Lookup missing key
- **WHEN** a key is looked up in a HAMT that does not contain it
- **THEN** `()` SHALL be returned (or the default if provided)

### Requirement: HAMT insert creates new path with structural sharing
HAMT insert SHALL create new nodes along the path from root to the modified leaf. Unchanged subtrees SHALL be shared (not copied). The operation SHALL return a new HAMT root without modifying the original.

#### Scenario: Insert into empty HAMT
- **WHEN** a key-value pair is inserted into an empty HAMT
- **THEN** a new HAMT containing exactly that entry SHALL be returned

#### Scenario: Insert preserves existing entries
- **WHEN** a new key is inserted into a HAMT with existing entries
- **THEN** all previous entries SHALL still be retrievable

#### Scenario: Insert updates existing key
- **WHEN** a key that already exists is inserted with a new value
- **THEN** the new value SHALL replace the old one and the count SHALL remain the same

### Requirement: HAMT remove creates new path without the entry
HAMT remove SHALL return a new HAMT root with the specified key removed. Unchanged subtrees SHALL be shared. If the key is not present, the original HAMT SHALL be returned unchanged.

#### Scenario: Remove existing key
- **WHEN** a key is removed from a HAMT
- **THEN** `hash-has-key?` for that key SHALL return `()` and other entries SHALL be unaffected

#### Scenario: Remove from collision node
- **WHEN** a key is removed from a collision node with 2 entries
- **THEN** the collision node SHALL be replaced with a direct leaf entry

#### Scenario: Remove non-existent key
- **WHEN** a key that does not exist is removed
- **THEN** the HAMT SHALL be returned unchanged
