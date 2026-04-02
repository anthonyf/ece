## ADDED Requirements

### Requirement: Golden source files exist for known expressions
A directory `tests/golden/` SHALL contain `.scm` files with fixed Scheme expressions that exercise key compiler features (arithmetic, closures, call/cc, macros, tail calls).

#### Scenario: Golden test files checked in
- **WHEN** the repository is cloned
- **THEN** `tests/golden/` SHALL contain `.scm` source files and corresponding `.expected` golden files

### Requirement: Golden expected files contain flat instruction output
Each `.expected` file SHALL contain the flat instruction list (without ecec-header) produced by compiling the corresponding `.scm` file. Labels SHALL be deterministic.

#### Scenario: Expected file format
- **WHEN** `tests/golden/basic-arithmetic.expected` is read
- **THEN** it SHALL contain one instruction per line, with deterministic label names

### Requirement: CI diffs compiler output against golden files
A CI step or make target SHALL compile each golden `.scm` file and diff the output against the `.expected` file. Any difference SHALL cause CI to fail.

#### Scenario: Compiler unchanged
- **WHEN** golden tests are run and the compiler has not changed
- **THEN** all diffs SHALL be empty and the test SHALL pass

#### Scenario: Compiler regression
- **WHEN** a compiler modification changes the instruction output for a golden file
- **THEN** the diff SHALL show the change and CI SHALL fail

### Requirement: Golden files are updatable
A make target (`make update-golden`) SHALL recompile all golden `.scm` files and overwrite the `.expected` files with current output.

#### Scenario: Developer intentionally changes compiler output
- **WHEN** a developer makes a deliberate compiler change and runs `make update-golden`
- **THEN** the `.expected` files SHALL be updated to reflect the new output
- **AND** the developer SHALL review the diff before committing

### Requirement: Deterministic label names in golden output
The compiler SHALL produce deterministic label names when compiling golden test files, so that the output is reproducible across runs.

#### Scenario: Same input produces same labels
- **WHEN** the same `.scm` file is compiled twice
- **THEN** the instruction output SHALL be identical, including all label names
