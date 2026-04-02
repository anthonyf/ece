## MODIFIED Requirements

### Requirement: compile-file emits .ecec with header
`compile-file` SHALL emit a `.ecec` file with a metadata header followed by a single flat instruction list containing all compiled forms, with explicit env-reset instructions between them.

#### Scenario: Compile prelude
- **WHEN** `(compile-file "src/prelude.scm")` is called
- **THEN** the output file SHALL start with `(ecec-header (space prelude) (macros (let and or ...)))`
- **AND** a single flat instruction list SHALL follow containing all forms' instructions concatenated with env-resets between them

#### Scenario: Macros executed at compile time
- **WHEN** a `define-macro` form is encountered during compilation
- **THEN** the macro SHALL be compiled and registered immediately
- **AND** subsequent forms SHALL be able to use the macro
- **AND** the macro name SHALL appear in the header's `macros` list

### Requirement: load-compiled creates named space
`load-compiled` SHALL read the `.ecec` header and create a named space, then read the single flat instruction list, assemble it into the space, and execute from PC 0.

#### Scenario: Load flat compiled file
- **WHEN** `(load-compiled "bootstrap/prelude.ecec")` is called
- **THEN** a space named `prelude` SHALL be created
- **AND** the single instruction list SHALL be assembled into that space
- **AND** execution SHALL start from PC 0

#### Scenario: CL loader reads flat format
- **WHEN** the CL runtime loads a flat .ecec file
- **THEN** it SHALL read exactly two s-expressions (header + instruction list) and execute the instruction list in one pass

#### Scenario: WASM loader reads flat format
- **WHEN** the WASM runtime loads a flat .ecec file
- **THEN** it SHALL scan a single instruction list for labels and build the instruction vector in one pass
