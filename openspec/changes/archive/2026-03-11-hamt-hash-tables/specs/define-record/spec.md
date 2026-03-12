## MODIFIED Requirements

### Requirement: Records are compatible with hash table operations
Records produced by `define-record` SHALL be HAMT-backed hash tables, fully compatible with `hash-ref`, `hash-set!`, `hash-set`, `hash-keys`, `hash-count`, `hash-table?`, and serialization via `save-continuation!`/`load-continuation`.

#### Scenario: Hash table operations work on records
- **WHEN** a record is created with `(make-point 10 20)`
- **THEN** `(hash-table? (make-point 10 20))` SHALL be `t` and `(hash-keys (make-point 10 20))` SHALL include `type`, `x`, and `y`
