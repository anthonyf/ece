## ADDED Requirements

### Requirement: WASM tests run in CI
The GitHub Actions workflow SHALL build the WASM runtime and run WASM tests on every push to main and every PR.

#### Scenario: WASM tests pass
- **WHEN** a PR is opened and all WASM tests pass
- **THEN** the CI check SHALL report success

#### Scenario: WASM tests fail
- **WHEN** a PR breaks the WASM runtime
- **THEN** the CI check SHALL fail with a non-zero exit code

### Requirement: make test-wasm target
A `make test-wasm` Makefile target SHALL compile the test suite to `.ececb` and run it via Node.js.

#### Scenario: Local developer usage
- **WHEN** a developer runs `make test-wasm`
- **THEN** the WASM tests SHALL compile and run with pass/fail output
