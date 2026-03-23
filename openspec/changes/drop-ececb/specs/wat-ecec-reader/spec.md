## ADDED Requirements

### Requirement: WAT loads .ecec text into compilation spaces
The WASM runtime SHALL export a `load_ecec(offset, len)` function that reads .ecec text from linear memory and loads it into a compilation space, returning the space ID.

#### Scenario: Load bootstrap file
- **WHEN** a .ecec file's text is placed in linear memory and `load_ecec` is called
- **THEN** a compilation space is created with the correct name, all instructions are loaded, and all labels are resolved

#### Scenario: Parse ecec-header
- **WHEN** the .ecec text starts with `(ecec-header (space prelude) (macros (cond let ...)))`
- **THEN** the space is named "prelude" and macros are registered

#### Scenario: Parse all instruction types
- **WHEN** the .ecec contains assign, test, branch, goto, save, restore, and perform instructions
- **THEN** each is correctly parsed into the corresponding `$instr` struct

#### Scenario: Parse constant values
- **WHEN** instructions contain fixnums, floats, strings, symbols, booleans (#t/#f), nil (()), and nested pairs/vectors
- **THEN** each value is correctly built as the corresponding WasmGC type

### Requirement: Short compiler labels
The compiler's `mc-make-label` SHALL emit labels of the form `L<counter>` instead of `mc-<name>-<counter>`.

#### Scenario: Compiled output uses short labels
- **WHEN** `(compile-file "src/prelude.scm")` is run
- **THEN** the .ecec output contains labels like `L11158` instead of `mc-primitive-branch-11158`

### Requirement: No .ececb files in bootstrap
The bootstrap directory SHALL contain only .ecec files. No .ececb files SHALL be produced or required.

#### Scenario: Bootstrap with .ecec only
- **WHEN** `make bootstrap` is run
- **THEN** only .ecec files are generated in bootstrap/

### Requirement: All tests pass unchanged
Existing test suites SHALL pass with the new loading mechanism.

#### Scenario: Full test suites
- **WHEN** `make test` and `make test-wasm` are run
- **THEN** all tests pass with zero failures
