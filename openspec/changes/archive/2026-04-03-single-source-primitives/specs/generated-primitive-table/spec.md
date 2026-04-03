## ADDED Requirements

### Requirement: Convention-based CL function resolution
The CL runtime SHALL resolve primitive implementations from `primitives.def` entries using naming conventions, without hand-maintained mapping lists.

#### Scenario: Standard wrapper resolution
- **WHEN** `primitives.def` contains a `core` primitive named `null?`
- **AND** a CL function `ece-null?` exists in the ECE package
- **THEN** the dispatch table SHALL map the primitive's ID to `#'ece-null?`

#### Scenario: Direct CL builtin resolution
- **WHEN** `primitives.def` contains a `core` primitive named `car`
- **AND** no `ece-car` function exists
- **THEN** the dispatch table SHALL map the primitive's ID to `#'car` from the CL package

#### Scenario: ECE package function resolution
- **WHEN** `primitives.def` contains a `core` primitive named `extend-environment`
- **AND** a function `extend-environment` exists in the ECE package
- **THEN** the dispatch table SHALL map the primitive's ID to that function

### Requirement: Override table for non-conventional mappings
A small override table SHALL map ECE names to CL function names where the naming convention does not apply.

#### Scenario: Override resolution
- **WHEN** `primitives.def` contains a primitive named `char->integer`
- **AND** the override table maps `char->integer` to `char-code`
- **THEN** the dispatch table SHALL map the primitive's ID to `#'char-code`

#### Scenario: Override takes precedence
- **WHEN** a primitive has both an override entry and a convention-matching function
- **THEN** the override SHALL take precedence
