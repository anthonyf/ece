## MODIFIED Requirements

### Requirement: load-compiled tolerates multi-space files
`load-compiled` SHALL continue to work for single-space .ecec files (current behavior) and SHALL NOT fail when given a file that happens to contain additional sections after the first.

#### Scenario: Single-space file loads as before
- **GIVEN** a standard single-space .ecec file produced by `compile-file`
- **WHEN** `(load-compiled "file.ecec")` is called
- **THEN** behavior SHALL be identical to the current implementation

#### Scenario: Multi-space file loads first space only
- **GIVEN** a multi-space .ecec bundle
- **WHEN** `(load-compiled "bundle.ecec")` is called
- **THEN** only the first space SHALL be loaded
- **AND** no error SHALL be raised due to remaining content in the file
