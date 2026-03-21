## ADDED Requirements

### Requirement: ECE self-hosted tests run in CI
The GitHub Actions workflow SHALL run `make test-ece` on every push to main and every PR.

#### Scenario: ECE tests pass
- **WHEN** all 496 ECE self-hosted tests pass
- **THEN** the CI step SHALL succeed

#### Scenario: ECE tests fail
- **WHEN** a PR breaks a prelude function or macro
- **THEN** the CI step SHALL fail
