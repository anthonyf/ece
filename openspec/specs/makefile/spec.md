## ADDED Requirements

### Requirement: make test runs the test suite
`make test` SHALL run the full test suite, including CL rove tests, ECE-native tests (via `bin/ece-test`), WASM tests, conformance tests, golden tests, and web-apps tests.

#### Scenario: Run tests
- **WHEN** `make test` is executed
- **THEN** the full test suite SHALL run
- **AND** the target SHALL fail if any sub-suite fails (non-zero exit from any underlying runner)

#### Scenario: ECE-native tests run via ece-test binary
- **WHEN** `make test-ece` is executed (directly or as a dependency of `make test`)
- **THEN** `bin/ece-test tests/ece/common tests/ece/cl-only` SHALL be invoked
- **AND** its exit code SHALL determine target success

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

## ADDED Requirements

### Requirement: make ece builds the native binary
`make ece` SHALL build the `bin/ece` native executable via `sb-ext:save-lisp-and-die`, with the bootstrap bundle preloaded into the image. It SHALL also refresh in-tree symlinks `bin/ece-repl`, `bin/ece-build`, `bin/ece-test` pointing at `bin/ece`.

#### Scenario: Build the binary
- **WHEN** `make ece` is executed
- **THEN** `bin/ece` SHALL exist as an executable file
- **AND** `bin/ece-repl`, `bin/ece-build`, `bin/ece-test` SHALL be symlinks to `bin/ece`
- **AND** running `bin/ece -V` SHALL print a version string

#### Scenario: Rebuild after source change
- **GIVEN** `bin/ece` exists and `src/ece-main.scm` is modified
- **WHEN** `make ece` is re-executed
- **THEN** `bin/ece` SHALL be rebuilt

### Requirement: make install deploys the SDK
`make install` SHALL install `bin/ece` and the `share/ece/` tree into `$DESTDIR$PREFIX/`. `PREFIX` SHALL default to `/usr/local`. `DESTDIR` SHALL be supported for staging installs.

#### Scenario: Install to default prefix
- **WHEN** `make install` is run
- **THEN** files SHALL be installed under `/usr/local/bin/` and `/usr/local/share/ece/`

#### Scenario: Install to user prefix
- **WHEN** `make install PREFIX=$HOME/.local` is run
- **THEN** files SHALL be installed under `$HOME/.local/bin/` and `$HOME/.local/share/ece/`

#### Scenario: make install depends on make ece
- **GIVEN** `bin/ece` does not yet exist
- **WHEN** `make install` is run
- **THEN** `make ece` SHALL be invoked as a dependency before any files are copied

### Requirement: make uninstall removes installed files
`make uninstall` SHALL remove every file placed by `make install` at the same `PREFIX`.

#### Scenario: Uninstall after install
- **GIVEN** `make install PREFIX=$HOME/.local` was run
- **WHEN** `make uninstall PREFIX=$HOME/.local` is run
- **THEN** all files installed under `$HOME/.local/bin/ece*` SHALL be removed
- **AND** `$HOME/.local/share/ece/` SHALL be removed

### ~~Requirement: make check-test-counts verifies baseline counts~~ (REMOVED)
**Removed**: The `test-counts.json` baseline is replaced by runner hygiene. `ece-test` reports `collected`, `ran`, `passed`, `failed` counts and exits non-zero on zero tests collected. Baseline-count regression gates are not maintained by mainstream test frameworks (pytest, Jest, Go, Rust, JUnit), and the manual update burden exceeded the signal.

**Migration**: Delete `tests/test-counts.json`, `scripts/check-test-counts.sh`, `make check-test-counts`, and `make update-test-counts`. Trust the runner exit codes. If richer regression tracking is desired later, use a coverage tool.
