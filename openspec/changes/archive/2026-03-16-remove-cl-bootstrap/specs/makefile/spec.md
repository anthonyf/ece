## MODIFIED Requirements

### Requirement: make image rebuilds the bootstrap image
`make image` SHALL use the self-hosting rebuild path: load `"ece"` system, load `.scm` sources via ECE's `load`, save image via `ece-save-image`. It SHALL NOT depend on the `"ece/cold"` ASDF system.

#### Scenario: Rebuild image
- **WHEN** `make image` is executed
- **THEN** the bootstrap image SHALL be regenerated at `bootstrap/ece.image`
- **AND** the rebuild SHALL use ECE's own compiler and reader (not the CL bootstrap compiler)

## ADDED Requirements

### Requirement: make clean removes stale FASL files
`make clean` SHALL also remove any `.fasl` files from `src/` in addition to clearing the SBCL FASL cache.

#### Scenario: Clean stale artifacts
- **WHEN** `make clean` is executed
- **THEN** the SBCL FASL cache SHALL be removed
- **AND** any `.fasl` files in `src/` SHALL be removed
