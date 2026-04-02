## ADDED Requirements

### Requirement: Identity hash tables on WASM
The WASM runtime SHALL support identity-based (eq?) hash tables via `%eq-hash-table`, `%eq-hash-ref`, and `%eq-hash-set!` primitives.

#### Scenario: Create and use eq hash table
- **WHEN** ECE code creates an eq hash table and stores/retrieves by identity
- **THEN** lookup uses `eq?` (reference identity), not `equal?` (structural equality)

#### Scenario: Distinguish structurally equal but distinct objects
- **WHEN** two pairs `(cons 1 2)` are created separately and used as keys
- **THEN** they map to different entries (unlike `equal?`-based hash tables)
