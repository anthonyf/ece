## ADDED Requirements

### Requirement: manifest file format
ECE SHALL have a primitive manifest file (`primitives.def`) containing S-expression entries of the form `(id name arity platform description)` where `id` is a non-negative integer, `name` is a symbol, `arity` is an integer (-1 for variadic), `platform` is one of `core`, `cl`, or `browser`, and `description` is a string.

#### Scenario: manifest is valid S-expressions
- **WHEN** `primitives.def` is read by the ECE reader or CL reader
- **THEN** each entry SHALL parse as a list of 5 elements

#### Scenario: IDs are unique
- **WHEN** the manifest is loaded
- **THEN** no two entries SHALL share the same numeric ID

#### Scenario: names are unique
- **WHEN** the manifest is loaded
- **THEN** no two entries SHALL share the same name

### Requirement: ID stability
Once a numeric ID is assigned to a primitive name in the manifest, that ID SHALL NOT be reassigned to a different primitive in any future version. IDs may be marked deprecated but not reused.

### Requirement: ID range conventions
Core primitives SHALL use IDs 0-99. CL platform primitives SHALL use IDs 100-199. Browser platform primitives SHALL use IDs 200-299. Future platforms SHALL use ranges 300+.

### Requirement: all existing primitives are in manifest
Every primitive with a CL implementation (resolved via naming convention or override table) SHALL have a corresponding entry in `primitives.def` with platform tag `core` or `cl`.

### Requirement: Boot-time validation of CL implementations
The CL runtime SHALL validate at boot that every `core` and `cl` platform primitive (excluding `ece`-platform entries) resolves to a CL function.

#### Scenario: Missing core primitive fails boot
- **WHEN** `primitives.def` contains a `core` primitive named `foo`
- **AND** no CL function can be resolved for `foo`
- **THEN** boot SHALL signal an error (not a warning)

#### Scenario: ECE-platform primitive skipped
- **WHEN** `primitives.def` contains an `ece` platform primitive
- **THEN** boot SHALL NOT require a CL function for it
- **AND** the dispatch table slot SHALL contain a stub

#### Scenario: Browser-platform primitive skipped
- **WHEN** `primitives.def` contains a `browser` platform primitive
- **THEN** boot SHALL NOT require a CL function for it

#### Scenario: core primitives present
- **WHEN** the manifest is loaded
- **THEN** it SHALL contain entries for `+`, `-`, `*`, `/`, `car`, `cdr`, `cons`, `list`, `null?`, `pair?`, `eq?`, `display`, `newline`, `read-char`, `write-char`, and all other standard primitives

#### Scenario: CL-only primitives tagged
- **WHEN** the manifest is loaded
- **THEN** `open-input-file`, `open-output-file`, `with-input-from-file`, `with-output-to-file`, `save-image!`, `trace`, `untrace` SHALL have platform tag `cl`

## MODIFIED Requirements (shrink-js-glue)

### Requirement: IDs are unique
- **WHEN** the manifest is loaded
- **THEN** no two entries SHALL share the same numeric ID

#### Scenario: IDs are unique
- **WHEN** `primitives.def` is read by the ECE reader or CL reader
- **THEN** no two entries SHALL share the same numeric ID

#### Scenario: Duplicate ID 165 is resolved
- **WHEN** `primitives.def` is checked for `%make-primitive`
- **THEN** there SHALL be exactly one entry with ID 165

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
