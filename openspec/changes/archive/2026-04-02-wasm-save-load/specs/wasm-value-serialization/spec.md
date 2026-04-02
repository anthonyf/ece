## ADDED Requirements

### Requirement: Round-trip serialization on WASM
`serialize-value` and `deserialize-value` SHALL produce correct round-trips for all ECE value types on the WASM runtime, including compiled procedures, continuations, primitives, parameters, hash tables, and shared structure.

#### Scenario: Serialize and deserialize a compiled procedure
- **WHEN** a compiled procedure is serialized and the result is deserialized
- **THEN** the deserialized value is a proper `$compiled-proc` struct with the same entry and env

#### Scenario: Serialize and deserialize a continuation
- **WHEN** a continuation captured by `call/cc` is serialized and deserialized
- **THEN** invoking the deserialized continuation resumes at the correct point

#### Scenario: Shared structure preserved
- **WHEN** a value with shared sub-structure is serialized and deserialized
- **THEN** the shared structure is preserved (same identity for shared parts)

#### Scenario: Save and load to localStorage
- **WHEN** `save-continuation!` writes to a filename and `load-continuation` reads it back
- **THEN** the loaded value equals the original (on WASM, uses localStorage-backed file I/O)
