## ADDED Requirements

### Requirement: Dead code removal preserves all behavior

Removing dead interpreter code, unused functions, and redundant storage SHALL NOT change any observable behavior. All existing tests MUST pass unchanged.

#### Scenario: All tests pass after cleanup
- **WHEN** the full test suite is run after all dead code is removed
- **THEN** every test passes with the same results as before the cleanup

### Requirement: README reflects compiler architecture

The README SHALL describe ECE as using a compiler (not an interpreter). It SHALL mention compilation to register machine instructions.

#### Scenario: README describes compilation
- **WHEN** a reader views the README
- **THEN** the description mentions the SICP 5.5 compiler and register machine instruction execution
