## ADDED Requirements

### Requirement: Makefile test-rove target exits with correct status

The `make test-rove` target SHALL run all rove test suites and check pass/fail status. It MUST exit 0 when all tests pass and exit 1 when any test fails. It uses `call-with-suite`/`all-suites`/`run-suite` because `rove:run` does not discover suites from FASL-cached files.

#### Scenario: All rove tests pass
- **WHEN** `make test-rove` is run and all 120 CL-side tests pass
- **THEN** the make target exits with status 0

#### Scenario: A rove test fails
- **WHEN** `make test-rove` is run and at least one test fails
- **THEN** the make target exits with status 1
