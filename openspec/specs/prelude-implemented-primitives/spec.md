# prelude-implemented-primitives Specification

## Purpose
Specify the migration of primitives whose bodies can be expressed in ECE without host-capability dependencies from `src/primitives.scm` (`define-host-primitive`) to `src/prelude.scm` (plain ECE `define`), while preserving observable behavior, keeping primitive IDs stable in `primitives.def`, and maintaining a clean two-pass bootstrap cycle at every commit.

## Requirements
### Requirement: `list` implemented in ECE prelude
The `list` function, previously implemented as a host primitive via `define-host-primitive` in `src/primitives.scm` with a `:cl` template, SHALL be implemented as ECE source in `src/prelude.scm`. Its observable behavior is unchanged. Compiled call sites SHALL dispatch through the prelude space's compiled zone rather than through the primitive ID table.

`list` is implemented as `(define (list . args) args)` — the rest-arg parameter is already bound to the argument list by the compiler, so returning it directly is the entire body. This works identically on every ECE runtime because rest-arg handling is part of the calling convention, not a host-specific feature.

No primitive ID renumbering SHALL occur — the removed primitive's slot in `primitives.def` remains present but its `platform` column is changed from `core` to `ece` so the CL runtime no longer generates a dispatch function for it.

#### Scenario: `list` callable from compiled code
- **WHEN** compiled code calls `(list 1 2 3)`
- **THEN** the call SHALL return `'(1 2 3)`
- **AND** the call SHALL dispatch through the prelude zone's compiled function (no primitive ID lookup)

#### Scenario: Removed primitive IDs are not reused
- **WHEN** a primitive is migrated to ECE
- **THEN** its slot in `primitives.def` SHALL keep the same ID number
- **AND** the `platform` field SHALL change from `core` to `ece`
- **AND** subsequent primitive IDs SHALL NOT be renumbered

#### Scenario: All test suites pass after migration
- **WHEN** `make test-rove`, `make test-ece`, `make test-conformance`, and `make test-wasm` are run after the migration
- **THEN** all four suites SHALL report zero failures

### Requirement: Two-pass bootstrap discipline
Each tier of the migration SHALL be a clean two-pass bootstrap cycle to keep the repository buildable from `main` at every commit.

#### Scenario: Pass 1 — add ECE definition
- **WHEN** the ECE definition is added to `src/prelude.scm`
- **THEN** the host-primitive declaration in `src/primitives.scm` SHALL remain in place
- **AND** `make bootstrap` SHALL succeed
- **AND** the test suites SHALL pass

#### Scenario: Pass 2 — remove host primitive
- **WHEN** the host-primitive declaration is removed from `src/primitives.scm`
- **AND** the corresponding line in `primitives.def` is changed from `core` to `ece`
- **THEN** `make bootstrap` SHALL succeed
- **AND** the test suites SHALL pass

#### Scenario: Migration is one commit
- **WHEN** the migration is implemented
- **THEN** the commit SHALL contain both passes (the consolidated end state)
- **AND** the commit message SHALL list the migrated primitives by name

