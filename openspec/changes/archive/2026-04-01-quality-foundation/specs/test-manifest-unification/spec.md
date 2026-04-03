## ADDED Requirements

### Requirement: Single test manifest for all platforms
The test suite SHALL have a single ordered list of test files that both CL and WASM platforms load. `run-common.scm` SHALL be the authoritative manifest. The Makefile's `WASM_TEST_SRCS` SHALL be derived from or replaced by this single list.

#### Scenario: Adding a new test file
- **WHEN** a developer adds a new test file to `run-common.scm`
- **THEN** the test file SHALL automatically be included in both CL and WASM test runs without editing a second manifest

#### Scenario: All previously WASM-excluded files are included
- **WHEN** the unified manifest is loaded on WASM
- **THEN** `test-callcc-tco.scm`, `test-errors.scm`, `test-error-messages.scm`, and `test-file-io.scm` SHALL all be loaded and executed (with platform-specific tests self-skipping via guards)

### Requirement: Platform-specific tests use runtime guards
Test files that contain platform-specific tests SHALL use `(when (platform-has? 'feature) ...)` guards around those tests rather than being excluded from the manifest entirely.

#### Scenario: try-eval-dependent test on WASM
- **WHEN** a test requires `try-eval` (CL-only) and runs on WASM
- **THEN** the test SHALL be skipped via `(when (platform-has? 'try-eval) ...)` and not cause a failure

#### Scenario: file-io test on WASM
- **WHEN** `test-file-io.scm` is loaded on WASM where `open-input-file` is not available
- **THEN** tests guarded by `(when (platform-has? 'open-input-file) ...)` SHALL be skipped, and unguarded tests SHALL run normally

### Requirement: WASM test build derives from run-common.scm
The WASM test build process SHALL concatenate the same files listed in `run-common.scm` (plus the WASM test runner) rather than maintaining a separate file list.

#### Scenario: Makefile test-wasm target
- **WHEN** `make test-wasm` is run
- **THEN** the concatenated test file SHALL include every file from `run-common.scm` in the same order, followed by `wasm/wasm-test-runner.scm`
