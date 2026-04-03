## ADDED Requirements

### Requirement: operations.def manifest file
The project SHALL have an `operations.def` file at the project root containing all register machine operations with stable numeric IDs.

#### Scenario: Manifest file format
- **WHEN** `operations.def` is read
- **THEN** each entry SHALL have the format `(id name arity description)` where id is a non-negative integer, name is the ECE operation symbol, arity is the argument count, and description is a human-readable string

#### Scenario: All CL operations present
- **WHEN** comparing `operations.def` to CL's `get-operation`
- **THEN** every operation in `get-operation` SHALL have a corresponding entry in the manifest

#### Scenario: All WASM operations present
- **WHEN** comparing `operations.def` to WASM's `$exec-machine-op` dispatch
- **THEN** every operation in the WASM dispatch SHALL have a corresponding entry in the manifest

### Requirement: Stable numeric IDs
Operation IDs in `operations.def` SHALL be permanent. An ID SHALL NOT be reused for a different operation once assigned.

#### Scenario: ID permanence
- **WHEN** an operation is removed from the manifest
- **THEN** its numeric ID SHALL remain reserved and SHALL NOT be assigned to a new operation

### Requirement: All hosts implement all operations
Every operation listed in `operations.def` SHALL be implemented by every host runtime (CL and WASM).

#### Scenario: CL implements all operations
- **WHEN** ECE boots on the CL runtime
- **THEN** every operation ID in the manifest SHALL resolve to a CL function

#### Scenario: WASM implements all operations
- **WHEN** ECE boots on the WASM runtime
- **THEN** every operation ID in the manifest SHALL have a dispatch branch in the executor

### Requirement: Operations are distinct from primitives
Operations SHALL be maintained in a separate manifest (`operations.def`) from primitives (`primitives.def`). Operation IDs and primitive IDs SHALL be independent numbering spaces.

#### Scenario: No ID collision
- **WHEN** operation ID 5 and primitive ID 5 both exist
- **THEN** they SHALL refer to different functions dispatched through different paths
