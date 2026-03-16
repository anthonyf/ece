## ADDED Requirements

### Requirement: make test runs the test suite
`make test` SHALL run the full ECE test suite via qlot and rove.

#### Scenario: Run tests
- **WHEN** `make test` is executed
- **THEN** the test suite SHALL run and report results

### Requirement: make repl launches an ECE REPL
`make repl` SHALL load the ECE system and start the interactive REPL.

#### Scenario: Launch REPL
- **WHEN** `make repl` is executed
- **THEN** an ECE REPL session SHALL start

### Requirement: make fmt formats source files
`make fmt` SHALL format all `.lisp` and `.asd` files with CL indentation and all `.scm` files with Scheme indentation using Emacs batch mode.

#### Scenario: Format files
- **WHEN** `make fmt` is executed
- **THEN** all source files SHALL be re-indented in place

### Requirement: make check-fmt verifies formatting
`make check-fmt` SHALL format files and fail with a non-zero exit code if any files were modified.

#### Scenario: Clean formatting
- **WHEN** `make check-fmt` is executed and all files are already formatted
- **THEN** the command SHALL exit with code 0

#### Scenario: Dirty formatting
- **WHEN** `make check-fmt` is executed and some files have incorrect indentation
- **THEN** the command SHALL restore the original files and exit with a non-zero code

### Requirement: make setup installs the pre-commit hook
`make setup` SHALL symlink `scripts/pre-commit` into `.git/hooks/pre-commit`.

#### Scenario: Install hook
- **WHEN** `make setup` is executed
- **THEN** `.git/hooks/pre-commit` SHALL be a symlink to `../../scripts/pre-commit`

### Requirement: make clean removes cached artifacts
`make clean` SHALL remove the FASL cache for this project.

#### Scenario: Clear cache
- **WHEN** `make clean` is executed
- **THEN** the SBCL FASL cache for ECE SHALL be removed

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
