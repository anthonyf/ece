## MODIFIED Requirements

### Requirement: make test runs the test suite
`make test` SHALL run the full test suite, including CL rove tests, ECE-native tests (via `bin/ece-test`), WASM tests, conformance tests, golden tests, and web-apps tests.

#### Scenario: Run tests
- **WHEN** `make test` is executed
- **THEN** the full test suite SHALL run
- **AND** the target SHALL fail if any sub-suite fails (non-zero exit from any underlying runner)

#### Scenario: ECE-native tests run via ece-test binary
- **WHEN** `make test-ece` is executed (directly or as a dependency of `make test`)
- **THEN** `bin/ece-test tests/ece/common tests/ece/cl-only` SHALL be invoked
- **AND** its exit code SHALL determine target success

## REMOVED Requirements

### Requirement: make check-test-counts verifies baseline counts
**Reason**: The `test-counts.json` baseline is replaced by runner hygiene. `ece-test` reports `collected`, `ran`, `passed`, `failed` counts and exits non-zero on zero tests collected. Baseline-count regression gates are not maintained by mainstream test frameworks (pytest, Jest, Go, Rust, JUnit), and the manual update burden exceeded the signal.

**Migration**: Delete `tests/test-counts.json`, `scripts/check-test-counts.sh`, `make check-test-counts`, and `make update-test-counts`. Trust the runner exit codes. If richer regression tracking is desired later, use a coverage tool.
