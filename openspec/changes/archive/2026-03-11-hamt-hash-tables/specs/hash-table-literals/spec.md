## MODIFIED Requirements

### Requirement: Self-evaluating hash tables
Hash table values SHALL be self-evaluating. The evaluator SHALL recognize HAMT-backed hash tables (tagged with `:hash-table`) and return them as-is without attempting function application.

#### Scenario: Literal in code
- **WHEN** `{name "Alice"}` appears in ECE code
- **THEN** the evaluator SHALL return it unchanged as a hash table value

#### Scenario: Hash table stored in variable
- **WHEN** `(define ht {name "Alice"})` is evaluated, then `ht` is referenced
- **THEN** `ht` SHALL evaluate to a hash table where `(hash-ref ht 'name)` is `"Alice"`

### Requirement: Serialization round-trip
Hash table values SHALL survive write/read cycles. HAMT-backed hash tables SHALL be serialized in a readable form and reconstructed on read.

#### Scenario: Write and read back
- **WHEN** a hash table `(hash-table 'name "Alice" 'age 30)` is written to a string via `write-to-string` and read back
- **THEN** the result SHALL be a hash table where `(hash-ref result 'name)` is `"Alice"` and `(hash-ref result 'age)` is `30`
