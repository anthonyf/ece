## Requirements

### Requirement: executor uses symbol space IDs
The executor's `space-id` local variable, `*executing-space-id*`, and `*current-space-id*` SHALL be symbols, not integers.

#### Scenario: Space switch with symbols
- **WHEN** `(goto (reg continue))` targets `(prelude . 4523)`
- **AND** the current space is `compiler`
- **THEN** the executor SHALL compare symbols with `eq`
- **AND** SHALL look up `prelude` in the symbol-keyed `*space-registry*`
- **AND** SHALL update `instrs`, `ltab`, and `space-id` locals

### Requirement: assign label qualifies with symbol
The `assign` instruction for `continue` with a `label` source SHALL qualify the resolved PC with the current space's symbol.

#### Scenario: Label assignment in space
- **WHEN** `(assign continue (label after-call-42))` executes in space `compiler`
- **THEN** the `continue` register SHALL be set to `(compiler . <resolved-pc>)`

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

### Requirement: executor dispatches halt instruction
The instruction executor SHALL recognize the `halt` instruction in its dispatch loop. When `(halt)` is encountered, the executor SHALL exit the loop immediately and return the current `val` register, equivalent to the `pc >= len` exit path.

#### Scenario: CL executor handles halt
- **WHEN** the CL `execute-instructions` function encounters `(halt)` at the current PC
- **THEN** it SHALL execute `(go loop-end)` to exit the tagbody loop
- **AND** the function SHALL return `val`

#### Scenario: WASM executor handles halt
- **WHEN** the WASM `execute-instructions` function encounters a `halt` instruction
- **THEN** it SHALL branch to the loop exit
- **AND** the function SHALL return the `val` register
