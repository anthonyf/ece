## ADDED Requirements

### Requirement: manifest file existence validation
The CL runtime SHALL verify that `primitives.def` and `operations.def` exist before attempting to parse them. If either file is missing, the system SHALL signal an error with a message identifying the missing file path.

#### Scenario: missing primitives.def
- **WHEN** `primitives.def` does not exist at the expected path
- **THEN** the system SHALL signal an error containing the expected file path

#### Scenario: missing operations.def
- **WHEN** `operations.def` does not exist at the expected path
- **THEN** the system SHALL signal an error containing the expected file path

### Requirement: manifest non-empty validation
After parsing a manifest file, the system SHALL verify that at least one entry was parsed. If no entries were found, the system SHALL signal an error identifying the file.

#### Scenario: empty primitives.def
- **WHEN** `primitives.def` exists but contains no valid entries
- **THEN** the system SHALL signal an error indicating that no primitives were found

### Requirement: primitive dispatch bounds check
`apply-primitive-procedure` SHALL validate that a numeric primitive ID is within the bounds of the dispatch table before accessing it. Out-of-range IDs SHALL produce an error message that includes the invalid ID value.

#### Scenario: out-of-range primitive ID
- **WHEN** `apply-primitive-procedure` receives a primitive with numeric ID exceeding the dispatch table size
- **THEN** the system SHALL signal an error containing the invalid ID value
- **AND** the error SHALL NOT be a raw CL array-index-out-of-bounds error
