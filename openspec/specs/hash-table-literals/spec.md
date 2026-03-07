## ADDED Requirements

### Requirement: Curly brace literal syntax
The ECE reader SHALL support `{k1 v1 k2 v2 ...}` syntax that produces a hash table value. Keys and values are read as data (not evaluated). The reader macro SHALL be defined on `*ece-readtable*`.

#### Scenario: Read symbol-keyed hash table
- **WHEN** the reader encounters `{name "Alice" age 30}`
- **THEN** it SHALL produce `(hash-table (NAME . "Alice") (AGE . 30))`

#### Scenario: Read string-keyed hash table
- **WHEN** the reader encounters `{"first" "Alice" "last" "Smith"}`
- **THEN** it SHALL produce `(hash-table ("first" . "Alice") ("last" . "Smith"))`

#### Scenario: Read empty hash table
- **WHEN** the reader encounters `{}`
- **THEN** it SHALL produce `(hash-table)`

#### Scenario: Read number-keyed hash table
- **WHEN** the reader encounters `{1 "one" 2 "two"}`
- **THEN** it SHALL produce `(hash-table (1 . "one") (2 . "two"))`

### Requirement: Self-evaluating hash tables
Hash table values (lists beginning with the symbol `hash-table`) SHALL be self-evaluating. The evaluator SHALL return them as-is without attempting function application.

#### Scenario: Literal in code
- **WHEN** `{name "Alice"}` appears in ECE code
- **THEN** the evaluator SHALL return `(hash-table (NAME . "Alice"))` unchanged

#### Scenario: Hash table stored in variable
- **WHEN** `(define ht {name "Alice"})` is evaluated, then `ht` is referenced
- **THEN** `ht` SHALL evaluate to `(hash-table (NAME . "Alice"))`

### Requirement: Serialization round-trip
Hash table values SHALL survive write/read cycles. The written form SHALL be readable by the standard ECE reader.

#### Scenario: Write and read back
- **WHEN** a hash table `{name "Alice" age 30}` is written to a string via `write-to-string` and read back
- **THEN** the result SHALL be `equal?` to the original hash table
