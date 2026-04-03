## MODIFIED Requirements

### Requirement: Boot-time validation of CL implementations
The CL runtime SHALL validate at boot that every `core` and `cl` platform primitive (excluding `ece`-platform entries) resolves to a CL function.

#### Scenario: Missing core primitive fails boot
- **WHEN** `primitives.def` contains a `core` primitive named `foo`
- **AND** no CL function can be resolved for `foo`
- **THEN** boot SHALL signal an error (not a warning)

#### Scenario: ECE-platform primitive skipped
- **WHEN** `primitives.def` contains an `ece` platform primitive
- **THEN** boot SHALL NOT require a CL function for it
- **AND** the dispatch table slot SHALL contain a stub

#### Scenario: Browser-platform primitive skipped
- **WHEN** `primitives.def` contains a `browser` platform primitive
- **THEN** boot SHALL NOT require a CL function for it
