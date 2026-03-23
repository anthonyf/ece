## ADDED Requirements

### Requirement: Op-id exhaustive verification
The WASM test runner SHALL verify that every operation name (all 22 operations, slots 17-38) resolves to the correct op-id via the WAT reader's `$ecec-op-id` function.

#### Scenario: All operation names resolve correctly
- **WHEN** each of the 22 operation names is checked via a WAT export
- **THEN** each returns its expected op-id (0-21), with no -1 (unrecognized) results

### Requirement: Instruction structural integrity after bootstrap
The WASM test runner SHALL validate all loaded instructions after bootstrap by scanning each space's instruction array.

#### Scenario: Op-ids in valid range
- **WHEN** all instructions in all bootstrap spaces are scanned
- **THEN** every instruction has opcode in 0-6 and, for assign-op/test/perform, the op-id ($c field) is in 0-21

#### Scenario: Label PCs in valid range
- **WHEN** instructions with label references (branch, goto-label, assign-label) are scanned
- **THEN** every label PC ($c field) is in range 0..space-len

#### Scenario: No stale label symbols in $val
- **WHEN** instructions with label references are scanned
- **THEN** the $val field is nil (not a symbol), confirming label resolution completed
