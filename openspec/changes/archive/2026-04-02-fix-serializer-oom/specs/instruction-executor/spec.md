## MODIFIED Requirements

### Requirement: extend-environment produces vector frames only
`extend-environment` SHALL always produce vector frames (simple-vectors consed onto the base env). The 3-arg named-list frame path SHALL be removed.

#### Scenario: Lambda application creates vector frame
- **WHEN** a compiled lambda is applied with arguments
- **THEN** `extend-environment` SHALL create a vector frame `#(arg1 arg2 ...)` consed onto the closure's env

### Requirement: %env-frame? identifies vector frames
`%env-frame?` (primitive 166) SHALL return true for vectors and false for all other types. This matches both CL vector frames and WASM GC struct frames.

#### Scenario: Vector is an env frame
- **WHEN** `(%env-frame? #(1 2 3))` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: Pair is not an env frame
- **WHEN** `(%env-frame? (cons 'a 'b))` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: lookup-variable-value handles vector and hash frames only
`lookup-variable-value` SHALL dispatch on frame type: hash-frame for O(1) named lookup, vector for skip (lexical addressing bypasses this function). The named-list scan path SHALL be removed.

#### Scenario: Global variable lookup
- **WHEN** looking up a variable defined in the global env
- **THEN** the hash-frame path SHALL find it via hash-table lookup
