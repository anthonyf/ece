## ADDED Requirements

### Requirement: compile-system produces multi-space .ecec bundle
`compile-system` SHALL accept a list of .scm filenames and an output path, compile each file to its own named compilation space, and write all spaces to a single .ecec bundle file.

#### Scenario: Compile two files into a bundle
- **GIVEN** files `a.scm` defining `(define (add1 x) (+ x 1))` and `b.scm` defining `(define (use-add1) (add1 5))`
- **WHEN** `(compile-system '("a.scm" "b.scm") "out.ecec")` is called
- **THEN** `out.ecec` SHALL contain two ecec-header + instruction-list sections
- **AND** the first section's space name SHALL be `a`
- **AND** the second section's space name SHALL be `b`

#### Scenario: Each space has its own source-map
- **WHEN** a bundle is produced from files `a.scm` and `b.scm`
- **THEN** the first section's ecec-header SHALL contain `(source-map "a.scm" ...)`
- **AND** the second section's ecec-header SHALL contain `(source-map "b.scm" ...)`

#### Scenario: Bundle is valid concatenation of single-space .ecec
- **WHEN** a bundle is produced
- **THEN** each section in the bundle SHALL be independently valid as a single-space .ecec file

#### Scenario: Empty file list produces empty output
- **WHEN** `(compile-system '() "out.ecec")` is called
- **THEN** `out.ecec` SHALL be an empty file

### Requirement: load-bundle loads multi-space .ecec bundles
`load-bundle` SHALL read a .ecec file containing one or more space sections, loading each sequentially. Each space's instructions SHALL execute before the next space is loaded.

#### Scenario: Load a two-space bundle
- **GIVEN** a bundle containing spaces `a` and `b`
- **WHEN** `(load-bundle "out.ecec")` is called
- **THEN** space `a` SHALL be created and executed first
- **AND** space `b` SHALL be created and executed second
- **AND** definitions from `a` SHALL be available when `b` executes

#### Scenario: Load a single-space bundle
- **GIVEN** a .ecec file with one space (standard compile-file output)
- **WHEN** `(load-bundle "file.ecec")` is called
- **THEN** it SHALL load successfully (backward compatible)

#### Scenario: Source-maps registered for each space
- **GIVEN** a bundle where each section has a source-map in its header
- **WHEN** the bundle is loaded
- **THEN** each space's source-map SHALL be registered in `*source-maps*`

### Requirement: CL runtime supports multi-space .ecec loading
The CL-side `load-ecec-file` SHALL support loading multi-space bundles by reading sections until EOF.

#### Scenario: CL loads multi-space bundle at boot
- **WHEN** a multi-space .ecec bundle is loaded via the CL runtime
- **THEN** each section SHALL be processed as a separate space
- **AND** source-maps SHALL be registered for each space

### Requirement: WASM runtime supports multi-space .ecec loading
The WASM `load_ecec` function SHALL support loading multi-space bundles.

#### Scenario: WASM loads multi-space bundle
- **WHEN** a multi-space .ecec bundle is loaded via the WASM runtime
- **THEN** each section SHALL be processed as a separate space
