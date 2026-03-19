## ADDED Requirements

### Requirement: codegen emits one host file per space
The codegen tool SHALL iterate the space registry and emit one CL source file per space. Each file SHALL contain a `defun` with a `tagbody` for that space's instructions, an entry dispatch `case` form, and cross-space exit via `return-from`.

#### Scenario: Generate code for a single space
- **WHEN** `generate-space-code` is called for a space with N instructions
- **THEN** a CL source file SHALL be written containing a `defun` named after the space
- **AND** the function SHALL have one label per instruction (L0 through L(N-1))
- **AND** the function SHALL accept `(pc val env proc argl continue stack)` as parameters
- **AND** the function SHALL return `(values space-id pc val env proc argl continue stack)` on exit

#### Scenario: Generate code for all spaces
- **WHEN** `generate-all-spaces` is called with an output directory
- **THEN** one CL source file SHALL be emitted per space in the registry
- **AND** a manifest file SHALL be emitted listing spaces in load order

### Requirement: codegen handles cross-space jumps
The generated code SHALL detect when a jump targets a different space and exit to the dispatcher.

#### Scenario: Goto register within same space
- **WHEN** generated code executes `goto (reg continue)` and the target space-id matches the current space
- **THEN** execution SHALL jump to the local PC via the entry dispatch

#### Scenario: Goto register to different space
- **WHEN** generated code executes `goto (reg continue)` and the target space-id differs from the current space
- **THEN** the function SHALL return the target space-id, target PC, and all registers to the dispatcher

### Requirement: codegen uses operation table per space
Each generated space file SHALL reference operations via `(aref *compiled-zone-op-table* N)`. The operation table SHALL be shared across all spaces and initialized from operation names at load time.

#### Scenario: Operation table initialization
- **WHEN** the generated manifest is loaded
- **THEN** the operation table SHALL be populated with CL function objects resolved from operation names
- **AND** all generated space files SHALL use the same table indices

### Requirement: generated files are independently compilable
Each generated space file SHALL be compilable by the host compiler (e.g., SBCL's `compile-file`) independently of other space files.

#### Scenario: Compile single space file
- **WHEN** `compile-file` is called on a single generated space file
- **THEN** it SHALL produce a valid FASL without errors
- **AND** the FASL SHALL be loadable after the manifest and operation table are loaded

#### Scenario: Load spaces incrementally
- **WHEN** generated space files are loaded in manifest order
- **THEN** each space's `compiled-fn` SHALL be set in the space registry
- **AND** execution SHALL use the compiled functions for loaded spaces and interpretation for unloaded spaces
