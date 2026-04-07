## MODIFIED Requirements

### Requirement: make clean removes cached artifacts
`make clean` SHALL remove the FASL cache for this project. `make clean-fasl` SHALL be an alias for `make clean`.

#### Scenario: Clear cache
- **WHEN** `make clean` is executed
- **THEN** the SBCL FASL cache for ECE SHALL be removed

#### Scenario: clean-fasl delegates to clean
- **WHEN** `make clean-fasl` is executed
- **THEN** `make clean` SHALL be invoked

### Requirement: make repl launches an ECE REPL
`make repl` SHALL load the ECE system and start the interactive REPL. `make run` SHALL be an alias for `make repl`.

#### Scenario: Launch REPL
- **WHEN** `make repl` is executed
- **THEN** an ECE REPL session SHALL start

#### Scenario: run delegates to repl
- **WHEN** `make run` is executed
- **THEN** `make repl` SHALL be invoked

## ADDED Requirements

### Requirement: TEST_OUTPUT_DIR is not created at parse time
The Makefile SHALL NOT use `$(shell ...)` with `:=` for `TEST_OUTPUT_DIR`. Instead, `TEST_OUTPUT_DIR` SHALL be a fixed path (`.tmp/test-output`) created by the test recipe when needed.

#### Scenario: Unrelated target does not create temp dir
- **WHEN** `make clean` is executed
- **THEN** no new temporary directory SHALL be created as a side effect

#### Scenario: Test target creates output dir
- **WHEN** `make test` is executed
- **THEN** `$(TEST_OUTPUT_DIR)` SHALL exist before test output is written
