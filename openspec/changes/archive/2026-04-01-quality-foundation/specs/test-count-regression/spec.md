## ADDED Requirements

### Requirement: Test count baselines are checked in
A file (`tests/test-counts.json`) SHALL store the expected minimum passing test counts for each test suite: CL ECE tests, CL rove tests, WASM ECE tests, WASM integration tests, and conformance tests.

#### Scenario: Baseline file format
- **WHEN** `tests/test-counts.json` is read
- **THEN** it SHALL contain a JSON object with keys for each suite and integer values representing the minimum expected passing count

### Requirement: CI fails if test count drops
The CI pipeline SHALL compare actual passing test counts against the baselines in `tests/test-counts.json`. If any suite's passing count is below its baseline, CI SHALL fail.

#### Scenario: Test accidentally removed
- **WHEN** a test file is removed and the passing count drops below baseline
- **THEN** CI SHALL fail with a message indicating which suite's count dropped and by how much

#### Scenario: Tests added
- **WHEN** new tests are added and the passing count exceeds the baseline
- **THEN** CI SHALL pass (baselines are minimums, not exact targets)

### Requirement: Baseline update mechanism
A make target (`make update-test-counts`) SHALL run all test suites, capture the passing counts, and update `tests/test-counts.json`.

#### Scenario: Developer adds new tests
- **WHEN** a developer adds tests and runs `make update-test-counts`
- **THEN** the baselines SHALL be updated to reflect the new higher counts
