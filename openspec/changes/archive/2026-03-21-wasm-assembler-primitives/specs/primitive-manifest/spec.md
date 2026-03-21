## MODIFIED Requirements

### Requirement: Space management primitives are core
Primitives IDs 125-135 SHALL be marked as `core` (all runtimes) instead of `cl` in primitives.def.

#### Scenario: Available on WASM
- **WHEN** the WASM runtime boots
- **THEN** `%create-space`, `%space-instruction-push!`, `%space-label-set!`, etc. SHALL be available
