## ADDED Requirements

### Requirement: Single-file bootstrap bundle
`make bootstrap` SHALL produce a single `bootstrap/bootstrap.ecec` containing all bootstrap sources compiled via `compile-system`.

#### Scenario: Bootstrap produces one file
- **WHEN** `make bootstrap` is run
- **THEN** `bootstrap/bootstrap.ecec` SHALL be created
- **AND** it SHALL contain sections for prelude, compiler, reader, assembler, compilation-unit, syntax-rules, and browser-lib

#### Scenario: Individual .ecec files are not produced
- **WHEN** `make bootstrap` completes
- **THEN** `bootstrap/` SHALL contain only `bootstrap.ecec`
- **AND** individual files like `prelude.ecec`, `compiler.ecec`, etc. SHALL NOT exist

### Requirement: CL runtime boots from bootstrap bundle
The CL runtime SHALL load `bootstrap/bootstrap.ecec` as a multi-section bundle, skipping platform-incompatible sections.

#### Scenario: CL boots and skips browser-lib
- **WHEN** the CL runtime boots from `bootstrap/bootstrap.ecec`
- **THEN** it SHALL load all sections except `browser-lib`
- **AND** all existing CL tests SHALL pass with no regressions

### Requirement: WASM runtime boots from bootstrap bundle
The WASM runtime SHALL load the bootstrap bundle using `loadEcecBundleText`.

#### Scenario: WASM boots all sections
- **WHEN** the WASM runtime loads the bootstrap bundle
- **THEN** it SHALL load and execute all sections including syntax-rules and browser-lib
- **AND** all existing WASM tests SHALL pass with no regressions
