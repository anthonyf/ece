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
