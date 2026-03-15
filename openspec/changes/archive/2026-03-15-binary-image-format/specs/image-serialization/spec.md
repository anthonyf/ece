## MODIFIED Requirements

### Requirement: save-image! serializes full system state
The `save-image!` primitive SHALL compact the instruction vector before serializing, removing unreachable instructions. It SHALL then write the compacted system state to a file using the **binary format** (instead of the flat line-oriented text format). The compaction algorithm SHALL remain unchanged. The CL runtime's `ece-%write-image` function SHALL be updated to call `binary-image-serialize` instead of `flat-image-serialize`.

#### Scenario: Save image produces binary format
- **WHEN** `(save-image! "test.image")` is called
- **THEN** the output file SHALL begin with the "ECE" magic bytes
- **AND** SHALL be in binary format

#### Scenario: Save image round-trips correctly
- **WHEN** an image is saved with `save-image!` and loaded with `load-image!`
- **THEN** all state SHALL be restored identically (same behavior as before, different format)

### Requirement: load-image! restores full system state
The `load-image!` primitive SHALL use `ece-load-image` which auto-detects binary vs text format. For binary images, it SHALL use the binary deserializer which builds resolved instructions directly (no `resolve-operations` pass needed).

#### Scenario: Load binary image skips resolve-operations
- **WHEN** a binary image is loaded
- **THEN** the instruction vector SHALL contain resolved `(op-fn #'function ...)` forms
- **AND** no separate `resolve-operations` loop SHALL be executed

#### Scenario: Load image restores parameter objects
- **WHEN** an image is saved with parameter objects (e.g., `*mc-compile-lexical-env*`, `current-input-port`)
- **AND** the image is loaded
- **THEN** all parameter objects SHALL be functional (get and set operations work)
- **AND** `parameterize` SHALL work correctly with restored parameters
