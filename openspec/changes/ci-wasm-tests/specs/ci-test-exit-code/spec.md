## MODIFIED Requirements

### Requirement: CI workflow runs all 3 test suites
The CI workflow SHALL run CL rove tests, ECE self-hosted tests, and WASM tests sequentially.

#### Scenario: All suites pass
- **WHEN** all 3 test suites pass
- **THEN** the overall CI check SHALL be green

#### Scenario: Any suite fails
- **WHEN** any of the 3 test suites has failures
- **THEN** the overall CI check SHALL be red
