## ADDED Requirements

### Requirement: Dynamic compilation space sizing
The `load_ecec` function SHALL create compilation spaces sized to the actual instruction count determined during Phase 1, rather than a fixed capacity.

#### Scenario: Large .ecec file loads successfully
- **WHEN** a `.ecec` file containing more than 65,536 instructions is loaded via `load_ecec`
- **THEN** the compilation space is created with sufficient capacity and all instructions are stored without an out-of-bounds trap

#### Scenario: Small .ecec file loads with exact sizing
- **WHEN** a `.ecec` file containing fewer than 65,536 instructions is loaded via `load_ecec`
- **THEN** the compilation space is created with capacity matching the actual instruction count (not over-provisioned to 65,536)

### Requirement: WASM test suite enabled in CI
The `test-wasm` target SHALL be included in the default `make test` target.

#### Scenario: make test runs WASM tests
- **WHEN** `make test` is executed
- **THEN** the `test-wasm` target runs as part of the test suite and the TODO comment about the loader bug is removed from the Makefile
