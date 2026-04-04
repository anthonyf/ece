## ADDED Requirements

### Requirement: Serializable continuations example uses correct function name
The README serializable continuations example SHALL use `load-saved` (not `load-continuation`) to load a saved continuation.

#### Scenario: Code example matches actual API
- **WHEN** a user reads the serializable continuations example
- **THEN** the restore line reads `(define k (load-saved "save.dat"))`

### Requirement: Bootstrap format references use .ecec
The README SHALL refer to `.ecec` files (not `.ececb`) and describe a single bootstrap bundle (not per-file).

#### Scenario: Key Features bullet
- **WHEN** a user reads the Key Features list
- **THEN** the bootstrap bullet says "single-bundle bootstrap" and references `.ecec`

#### Scenario: Architecture description
- **WHEN** a user reads the Architecture intro
- **THEN** it references `.ecec` bootstrap files, not `.ececb`

### Requirement: Standard Library listing contains only functions that exist
The README Standard Library listing SHALL NOT include `fmt` or `lines`.

#### Scenario: fmt and lines removed
- **WHEN** a user reads the Standard Library section
- **THEN** `fmt` and `lines` do not appear

### Requirement: Runtime line counts are approximately correct
The CL runtime description SHALL state "~2,300 lines". The WASM runtime description SHALL state "~6,500 lines".

#### Scenario: CL runtime line count
- **WHEN** a user reads the CL Runtime subsection
- **THEN** it says "~2,300 lines"

#### Scenario: WASM runtime line count
- **WHEN** a user reads the WASM Runtime subsection
- **THEN** it says "~6,500 lines"

### Requirement: Test documentation reflects actual make targets
The README SHALL show `make test` as the single command that runs the full suite, and list what it includes.

#### Scenario: make test description
- **WHEN** a user reads the Testing section
- **THEN** `make test` is described as running the full suite (CL, ECE self-hosted, WASM, conformance, golden)
- **THEN** the separate `make test-wasm` line is removed or folded into a note about individual targets
