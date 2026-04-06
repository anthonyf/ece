## MODIFIED Requirements

### Requirement: Test files organized by category
The test suite SHALL consist of `.scm` files under `tests/ece/`, partitioned by runtime eligibility into subdirectories. Tests that run on any runtime SHALL live in `tests/ece/common/`. Tests that require CL-specific primitives SHALL live in `tests/ece/cl-only/`. Files outside these directories SHALL NOT be treated as test files.

#### Scenario: Test file structure
- **WHEN** a developer lists files in `tests/ece/`
- **THEN** the layout SHALL include `common/` and `cl-only/` subdirectories
- **AND** `common/` SHALL contain `test-*.scm` files exercising pure-ECE semantics (arithmetic, lists, strings, vectors, hash-tables, control-flow, closures, macros, TCO, call/cc, types, higher-order, records, errors, parameters)
- **AND** `cl-only/` SHALL contain `test-*.scm` files that need CL-only primitives (compile-file, continuation serialization, source-location tracking, SDK-integration tests)

#### Scenario: WASM bundle eligibility
- **GIVEN** a file under `tests/ece/common/`
- **WHEN** the WASM test bundle is assembled
- **THEN** that file SHALL be included in the bundle

- **GIVEN** a file under `tests/ece/cl-only/`
- **WHEN** the WASM test bundle is assembled
- **THEN** that file SHALL NOT be included

### Requirement: Makefile integration
A `make test-ece` target SHALL invoke `bin/ece-test tests/ece/common tests/ece/cl-only` and propagate its exit code.

#### Scenario: Run via make
- **WHEN** `make test-ece` is executed
- **THEN** `bin/ece-test` SHALL be invoked with the common and cl-only directories as positional arguments
- **AND** all discovered tests SHALL run
- **AND** the make target SHALL exit 0 on success or 1 on test failure

## REMOVED Requirements

### Requirement: Single entry point
**Reason**: The single `run-all.scm` orchestrator is replaced by `ece-test`'s directory-based discovery. Contributors and tools invoke `bin/ece-test tests/ece/common tests/ece/cl-only` (or any subset) instead of loading an orchestrator file.

**Migration**: Replace `(load "tests/ece/run-all.scm") (run-tests)` with `bin/ece-test tests/ece/common tests/ece/cl-only` at the shell, or `(ece-test-main '("tests/ece/common" "tests/ece/cl-only"))` at the ECE REPL. The same applies to `run-common.scm`, `run-cl.scm`, and `run-wasm.scm`; all are removed and replaced by directory-based discovery.
