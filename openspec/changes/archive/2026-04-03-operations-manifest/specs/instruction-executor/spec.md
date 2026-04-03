## MODIFIED Requirements

### Requirement: lookup-variable-value handles vector and hash frames only
`lookup-variable-value` SHALL dispatch on frame type: hash-frame for O(1) named lookup, vector for skip (lexical addressing bypasses this function). The named-list scan path SHALL be removed.

Operation dispatch SHALL use a manifest-driven lookup table indexed by numeric operation ID, rather than a hardcoded name-to-function mapping.

#### Scenario: Global variable lookup
- **WHEN** looking up a variable defined in the global env
- **THEN** the hash-frame path SHALL find it via hash-table lookup

#### Scenario: CL operation resolution by ID
- **WHEN** `resolve-operations` processes `(op lookup-variable-value)` at assembly time
- **THEN** it SHALL resolve the name to the operation's numeric ID and then to the CL function via `*operation-dispatch-table*`

#### Scenario: WASM operation resolution by ID
- **WHEN** the WASM .ecec loader encounters `(op lookup-variable-value)`
- **THEN** it SHALL resolve the name to the canonical numeric ID from `operations.def`
- **AND** the executor SHALL dispatch to the correct WASM function for that ID
