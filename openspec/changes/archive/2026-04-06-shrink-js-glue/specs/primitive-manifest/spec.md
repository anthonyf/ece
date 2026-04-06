## MODIFIED Requirements

### Requirement: IDs are unique
- **WHEN** the manifest is loaded
- **THEN** no two entries SHALL share the same numeric ID

#### Scenario: IDs are unique
- **WHEN** `primitives.def` is read by the ECE reader or CL reader
- **THEN** no two entries SHALL share the same numeric ID

#### Scenario: Duplicate ID 165 is resolved
- **WHEN** `primitives.def` is checked for `%make-primitive`
- **THEN** there SHALL be exactly one entry with ID 165
