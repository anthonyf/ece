## MODIFIED Requirements

### Requirement: All tests become common
With file I/O implemented on WASM, all 4 CL-only test files SHALL move to `run-common.scm`. The `run-cl.scm` file SHALL be empty.

#### Scenario: Full test suite on WASM
- **WHEN** `run-common.scm` is executed on the WASM host
- **THEN** all tests (including file I/O, serialization, compilation units, cross-space) SHALL pass

#### Scenario: CL test count unchanged
- **WHEN** `run-all.scm` is executed on the CL host
- **THEN** the same total number of tests SHALL pass as before
