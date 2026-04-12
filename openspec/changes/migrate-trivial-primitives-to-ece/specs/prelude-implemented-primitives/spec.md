## ADDED Requirements

### Requirement: Trivial primitives implemented in ECE prelude
The following functions, previously implemented as host primitives via `define-host-primitive` in `src/primitives.scm` with `:cl` templates, SHALL be implemented as ECE source in `src/prelude.scm`. Their observable behavior is unchanged. Compiled call sites SHALL dispatch through the prelude space's compiled zone rather than through the primitive ID table.

The migrated functions are:

- **List accessors** (9): `compiled-procedure-entry`, `compiled-procedure-env`, `continuation-stack`, `continuation-conts`, `continuation-winds`, `%primitive-id-of`, `%global-env-frame`, `port-line`, `port-col`
- **List constructors** (4): `%make-compiled-procedure`, `%make-continuation`, `%make-primitive`, `make-parameter`
- **Structural and tagged-list predicates** (11): `input-port?`, `output-port?`, `port?`, `parameter?`, `keyword?`, `null?`, `compiled-procedure?`, `continuation?`, `primitive?`, `procedure?`, `%env-frame?`
- **Trivial standalone** (2): `list`, `clear-screen`

Each function SHALL preserve its existing public name, parameter list, and return value. No primitive ID renumbering SHALL occur — removed primitive IDs are left empty so existing `.ecec` files remain valid.

#### Scenario: Migrated function callable from compiled code
- **WHEN** compiled code calls one of the migrated functions (e.g., `(compiled-procedure-entry proc)`)
- **THEN** the call SHALL succeed and return the same value as the prior host-primitive implementation
- **AND** the call SHALL dispatch through the prelude zone's compiled function (no primitive ID lookup)

#### Scenario: Migrated function callable from REPL
- **WHEN** the REPL evaluates `(keyword? :foo)` or any other migrated function
- **THEN** the call SHALL succeed and return the same value as the prior host-primitive implementation

#### Scenario: Removed primitive IDs are not reused
- **WHEN** a primitive is removed from `src/primitives.scm`
- **THEN** its slot in `primitives.def` SHALL remain unused (commented or absent)
- **AND** subsequent primitive IDs SHALL NOT be renumbered
- **AND** existing `.ecec` files referencing the removed ID's slot by number SHALL still load (the slot is no longer dispatched, but the ID space is preserved)

#### Scenario: All test suites pass after migration
- **WHEN** `make test-rove`, `make test-ece`, `make test-conformance`, and `make test-wasm` are run after the full migration
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
- **AND** the corresponding line in `primitives.def` is removed (or commented)
- **THEN** `make bootstrap` SHALL succeed
- **AND** the test suites SHALL pass

#### Scenario: Each tier is one commit
- **WHEN** a tier is implemented
- **THEN** the commit SHALL contain both passes (the consolidated end state)
- **AND** the commit message SHALL list the migrated primitives by name
