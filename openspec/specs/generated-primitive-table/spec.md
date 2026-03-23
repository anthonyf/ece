## ADDED Requirements

### Requirement: Primitive table generated from primitives.def
The WASM glue layer SHALL read primitive ID→name mappings from a generated file derived from `primitives.def`, not from a hand-maintained inline array.

#### Scenario: Adding a new primitive
- **WHEN** a new primitive is added to `primitives.def` and the generation script is run
- **THEN** the generated JSON contains the new entry and `glue.js` registers it without any manual edit

#### Scenario: Generated file matches source
- **WHEN** `make test-wasm` runs
- **THEN** a staleness check verifies the generated JSON matches the current `primitives.def`

### Requirement: Platform filtering
The generated table SHALL include only primitives relevant to the WASM platform (platform = `core` or `browser`), excluding CL-only primitives.

#### Scenario: CL-only primitives excluded
- **WHEN** `primitives.def` contains entries with platform `cl`
- **THEN** the generated JSON does not include those entries
