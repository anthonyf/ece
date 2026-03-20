## MODIFIED Requirements

### Requirement: Primitive manifest includes write-byte
The `primitives.def` manifest SHALL include a `write-byte` primitive for binary output, assigned a stable numeric ID in the core range.

#### Scenario: write-byte in manifest
- **WHEN** `primitives.def` is read
- **THEN** it SHALL contain an entry for `write-byte` with arity 2 (byte value and port), platform `core`

### Requirement: Browser platform primitive range documented
The `primitives.def` manifest SHALL document the browser platform primitive range (200-299) with initial reserved entries for future browser-specific primitives.

#### Scenario: Browser range header present
- **WHEN** `primitives.def` is read
- **THEN** the 200-299 range section SHALL exist with commentary describing its purpose for the WASM/browser runtime
