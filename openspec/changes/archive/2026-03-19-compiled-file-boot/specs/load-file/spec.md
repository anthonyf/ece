## MODIFIED Requirements

### Requirement: load creates a named space from filename
`(load "src/my-game.scm")` SHALL create a space named with a symbol derived from the filename.

#### Scenario: Load a source file
- **WHEN** `(load "src/prelude.scm")` is called
- **THEN** a space named `prelude` SHALL be created (derived from filename, stripping path and extension)
- **AND** all forms SHALL be compiled and assembled into that space

#### Scenario: Load at REPL
- **WHEN** `(load "my-game.scm")` is called at the REPL
- **THEN** a space named `my-game` SHALL be created
- **AND** the code SHALL execute with cross-space calls to prelude, compiler, etc. working via the global environment
