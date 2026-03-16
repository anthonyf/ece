## MODIFIED Requirements

### Requirement: Bootstrap image can be regenerated from source
`make image` SHALL rebuild the bootstrap image using ECE's own self-hosting compiler. It loads the `"ece"` ASDF system (runtime + existing image), uses ECE's `load` to compile all `.scm` sources, and calls `ece-save-image` to write the result. The `"ece/cold"` ASDF system is no longer available.

#### Scenario: Generate bootstrap image
- **WHEN** `make image` is run
- **THEN** it SHALL load the `"ece"` system (runtime + existing image)
- **AND** ECE SHALL load `.scm` sources using its own reader and compiler
- **AND** a bootstrap image SHALL be written to `bootstrap/ece.image`
- **AND** the image SHALL contain the fully bootstrapped system (prelude, compiler, reader, assembler, compaction)

#### Scenario: Fast startup target
- **WHEN** `make run` is run
- **THEN** ECE SHALL start using the `"ece"` system (runtime + image)
- **AND** the REPL SHALL be functional
