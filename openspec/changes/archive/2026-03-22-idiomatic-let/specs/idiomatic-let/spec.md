## ADDED Requirements

### Requirement: No behavioral changes from refactoring
All conversions from internal `define` to `let`/`let*`/named-`let` SHALL preserve identical runtime behavior. The test suite SHALL pass unchanged after each file is refactored.

#### Scenario: All tests pass after refactoring
- **WHEN** `make test` and `make test-wasm` are run after the refactoring
- **THEN** all existing tests pass with zero failures
