## ADDED Requirements

### Requirement: JS storage imports for WASM
The JS glue SHALL provide `storage_read` and `storage_write` imports that map to localStorage (browser) or an in-memory Map (Node.js).

#### Scenario: Write and read round-trip
- **WHEN** WASM calls `storage_write` with filename "test.dat" and content "hello"
- **AND** WASM then calls `storage_read` with filename "test.dat"
- **THEN** the returned content SHALL be "hello"

#### Scenario: Node.js fallback
- **WHEN** running in Node.js (no localStorage)
- **THEN** a Map-based fallback SHALL provide the same read/write behavior
