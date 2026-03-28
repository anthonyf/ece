## ADDED Requirements

### Requirement: HAMT code preserved as loadable library
The HAMT implementation SHALL be available at `lib/hamt.scm` as an optional library providing persistent (immutable) hash maps.

#### Scenario: Load HAMT library
- **WHEN** `(load "lib/hamt.scm")` is called
- **THEN** HAMT functions (`hamt-empty`, `hamt-set`, `hamt-ref`, `hamt-remove`, etc.) SHALL be available

### Requirement: HAMT has its own test file
A `tests/ece/test-hamt.scm` file SHALL test the HAMT implementation independently from platform hash tables.

#### Scenario: HAMT tests pass on CL
- **WHEN** `test-hamt.scm` is loaded and run on the CL host
- **THEN** all HAMT-specific tests SHALL pass
