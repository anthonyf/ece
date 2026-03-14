## MODIFIED Requirements

### Requirement: flat deserializer restores global state
After reading the flat-format file, the deserializer SHALL destructure the top-of-stack value as a 7-element list and restore all global state identically to the current `ece-load-image`. Environment frames that are vectors SHALL be restored as vectors.

#### Scenario: Full image load restores system state with vector frames
- **WHEN** `ece-load-image` is called with an image containing vector-backed lexical frames
- **THEN** `*global-env*` SHALL be restored with vector frames intact
- **AND** `lexical-ref` operations SHALL work correctly on the restored environment
- **AND** all prelude functions, macros, and primitives SHALL work correctly

#### Scenario: Image round-trip preserves frame types
- **WHEN** an image is saved and then loaded
- **THEN** lexical frames SHALL remain as vectors
- **AND** the global frame SHALL remain as a list-based frame
