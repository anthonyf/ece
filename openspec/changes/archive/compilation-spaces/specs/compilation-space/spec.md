## ADDED Requirements

### Requirement: space registry manages compilation spaces
The runtime SHALL maintain a space registry (`*space-registry*`) that maps space IDs (non-negative integers) to space records. Each space record SHALL contain: an instruction array (source form), a resolved instruction array, a local label table, a name (string), and an optional compiled host function.

#### Scenario: Create a new space
- **WHEN** `create-space` is called with a name (e.g., `"prelude"`)
- **THEN** a new space record SHALL be allocated with empty instruction and label arrays
- **AND** the space SHALL be registered in `*space-registry*` at the next available index
- **AND** the space ID (index) SHALL be returned

#### Scenario: Look up a space by ID
- **WHEN** `get-space` is called with a valid space ID
- **THEN** the corresponding space record SHALL be returned

#### Scenario: Look up a space by name
- **WHEN** `find-space-by-name` is called with a name
- **THEN** the space with that name SHALL be returned, or nil if not found

### Requirement: space-qualified addresses represent procedure entry points
Procedure entry points and continuation return addresses SHALL be represented as `(space-id . local-pc)` pairs instead of bare integers. `make-compiled-procedure` SHALL store the qualified address. `compiled-procedure-entry` SHALL return the qualified address.

#### Scenario: Make compiled procedure with qualified address
- **WHEN** `(make-compiled-procedure (cons space-id local-pc) env)` is called
- **THEN** the resulting procedure's entry SHALL be the cons pair `(space-id . local-pc)`

#### Scenario: Extract entry from compiled procedure
- **WHEN** `compiled-procedure-entry` is called on a compiled procedure
- **THEN** it SHALL return the `(space-id . local-pc)` pair

#### Scenario: Continuation addresses are space-qualified
- **WHEN** a compiled procedure call sets the `continue` register
- **THEN** the value SHALL be a `(space-id . local-pc)` pair pointing to the return address in the calling space

### Requirement: spaces support instruction assembly
Each space SHALL accept instructions via an assembly operation that appends to the space's instruction arrays and registers labels in the space's local label table with space-local PCs.

#### Scenario: Assemble instructions into a space
- **WHEN** instructions are assembled into a space
- **THEN** the source instructions SHALL be appended to the space's source instruction array
- **AND** the resolved instructions SHALL be appended to the space's resolved instruction array
- **AND** labels SHALL be registered in the space's local label table with local PC offsets (starting from 0 within the space)
- **AND** the local start PC SHALL be returned

#### Scenario: Multiple assemblies into the same space
- **WHEN** two instruction sequences are assembled into the same space sequentially
- **THEN** the second sequence's PCs SHALL start after the first sequence's end
- **AND** labels from both sequences SHALL coexist in the space's label table

### Requirement: spaces track compiled host functions
Each space SHALL have an optional `compiled-fn` slot. When set, the space's code runs as native host code instead of being interpreted from the instruction array.

#### Scenario: Space without compiled function
- **WHEN** a space has no `compiled-fn` set
- **THEN** the executor SHALL interpret the space's instruction array

#### Scenario: Space with compiled function
- **WHEN** a space's `compiled-fn` is set to a host function
- **THEN** the executor SHALL call the host function instead of interpreting instructions
- **AND** the host function SHALL receive and return registers via multiple values
