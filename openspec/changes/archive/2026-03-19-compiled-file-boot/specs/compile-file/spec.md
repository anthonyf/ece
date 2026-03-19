## MODIFIED Requirements

### Requirement: compile-file emits .ecec with header
`compile-file` SHALL emit a `.ecec` file with a metadata header containing the space name and macro list, followed by compiled unit instruction lists.

#### Scenario: Compile prelude
- **WHEN** `(compile-file "src/prelude.scm")` is called
- **THEN** the output file SHALL start with `(ecec-header (space prelude) (macros (let and or ...)))`
- **AND** each compiled form SHALL follow as an s-expression instruction list

#### Scenario: Macros executed at compile time
- **WHEN** a `define-macro` form is encountered during compilation
- **THEN** the macro SHALL be compiled and registered immediately
- **AND** subsequent forms SHALL be able to use the macro
- **AND** the macro name SHALL appear in the header's `macros` list

### Requirement: load-compiled creates named space
`load-compiled` SHALL read the `.ecec` header and create a named space before executing units.

#### Scenario: Load compiled file
- **WHEN** `(load-compiled "bootstrap/prelude.ecec")` is called
- **THEN** a space named `prelude` SHALL be created
- **AND** all units SHALL be assembled into that space
- **AND** macros from the header SHALL be registered in `*compile-time-macros*`
