## ADDED Requirements

### Requirement: WAT reader produces identical instructions to binary loader
For any `.ecec` file, the WAT reader SHALL produce instructions with identical `$val` fields (by structural comparison) to those produced by the binary loader for the same file.

#### Scenario: Prelude val field comparison
- **WHEN** the prelude `.ecec` is loaded via both the WAT reader and the binary loader
- **THEN** every instruction's val field has the same printed representation in both

#### Scenario: serialize-value works from prelude
- **WHEN** `serialize-value` is called from the prelude-compiled version (not runtime-compiled)
- **THEN** it produces correct output for all ECE value types without crashing

#### Scenario: yield works from prelude
- **WHEN** `yield` is called from the prelude-compiled version
- **THEN** the winding wrapper's closure contains a valid `$continuation` at the expected offset
