## MODIFIED Requirements

### Requirement: Hash table operations use platform primitives
Hash table operations (`hash-ref`, `hash-set!`, `hash-remove!`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-table?`) SHALL be implemented as platform primitives rather than ECE functions wrapping the HAMT.

#### Scenario: hash-ref on both hosts
- **WHEN** `(hash-ref ht 'key)` is called on CL or WASM
- **THEN** the primitive implementation SHALL handle the lookup natively without calling ECE functions

#### Scenario: Existing test suite passes unchanged
- **WHEN** `test-hash-tables.scm` is run
- **THEN** all tests SHALL pass with the same results as before (API is unchanged)

#### Scenario: Records work unchanged
- **WHEN** `(define-record point x y)` and `(point-x (make-point 10 20))` are evaluated
- **THEN** the result SHALL be `10` (records use hash table API, not HAMT internals)
