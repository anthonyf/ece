## ADDED Requirements

### Requirement: make image rebuilds using ECE's own compiler and reader
`make image` SHALL load the `"ece"` ASDF system (runtime + existing image), then use ECE's own `load` function to read and compile `.scm` source files in order: `prelude.scm`, `compiler.scm`, `reader.scm`, `assembler.scm`, `compaction.scm`. After loading, it SHALL call `ece-save-image` to write the new image to `bootstrap/ece.image`.

#### Scenario: Self-hosting image rebuild
- **WHEN** `make image` is run with a valid `bootstrap/ece.image` present
- **THEN** ECE SHALL load the existing image, recompile all `.scm` sources using its own compiler/reader, and save a new image to `bootstrap/ece.image`
- **AND** the resulting image SHALL be loadable by the `"ece"` ASDF system
- **AND** all tests SHALL pass against the rebuilt image

#### Scenario: Round-trip rebuild preserves functionality
- **WHEN** `make image` is run and then `make test` is run
- **THEN** the full test suite SHALL pass
