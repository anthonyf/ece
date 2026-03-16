## ADDED Requirements

### Requirement: CI exits non-zero when tests fail
The CI test workflow SHALL exit with a non-zero exit code when any rove test fails. The workflow SHALL call `rove:run` directly and use its boolean return value to determine the exit code.

#### Scenario: All tests pass
- **WHEN** all rove tests pass
- **THEN** the CI step SHALL exit with code 0

#### Scenario: One or more tests fail
- **WHEN** one or more rove tests fail
- **THEN** the CI step SHALL exit with code 1
