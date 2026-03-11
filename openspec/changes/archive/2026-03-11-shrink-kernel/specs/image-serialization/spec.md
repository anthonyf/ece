## MODIFIED Requirements

### Requirement: save-image! serializes full system state
The `save-image!` primitive SHALL compact the instruction vector before serializing, removing unreachable instructions. It SHALL then write the compacted system state to a file. The compaction SHALL operate on copies — the live system state SHALL remain untouched.

The compaction algorithm SHALL be implemented in ECE code (not the CL runtime). The CL runtime SHALL provide only the low-level serialization primitive (`%write-image`).

The compaction algorithm SHALL:
1. Collect block boundaries from the procedure-name table via `%procedure-name-entries`
2. Determine reachable entry PCs by walking all `(compiled-procedure pc env)` values in `*global-env*` and the macro table (via `%macro-table-entries`), transitively including continuations
3. Use sorted block boundaries to partition the instruction vector; retain blocks containing any reachable PC
4. Transitively retain blocks referenced by labels in already-retained blocks (via scanning source instructions with `%instruction-source-ref`)
5. Copy only retained blocks into a compacted instruction list, building an old-pc → new-pc remapping
6. Deep-copy the global environment and macro table, remapping all PCs in compiled procedures and continuations
7. Remap the label table and procedure-name table using the same mapping
8. Pass the compacted state to `%write-image` for serialization

#### Scenario: Save image after compiling code
- **WHEN** `(save-image! "test.image")` is called after defining functions and variables
- **THEN** a file `test.image` SHALL be created containing compacted state with no dead instructions
- **AND** `save-image!` SHALL return `#t`

#### Scenario: Save image overwrites existing file
- **WHEN** `(save-image! "test.image")` is called and the file already exists
- **THEN** the file SHALL be overwritten with the current compacted state

#### Scenario: Compaction removes dead code from redefinitions
- **WHEN** a function is defined, then redefined with a different body
- **AND** `(save-image! "test.image")` is called
- **THEN** the saved image SHALL contain only the instructions for the latest definition
- **AND** the saved instruction vector SHALL be smaller than the live instruction vector

#### Scenario: Compaction preserves live system state
- **WHEN** `(save-image! "test.image")` is called
- **THEN** the live instruction vector, environment, macro table, and label table SHALL be unchanged
- **AND** subsequent evaluation SHALL continue to work correctly using the original (uncompacted) state

#### Scenario: Anonymous lambdas are preserved
- **WHEN** a closure is created via `(lambda ...)` and stored in a variable
- **AND** `(save-image! "test.image")` is called
- **THEN** the saved image SHALL include the anonymous lambda's instructions
- **AND** invoking the restored closure after `load-image!` SHALL work correctly
