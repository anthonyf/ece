## ADDED Requirements

### Requirement: make install deploys the SDK under PREFIX
`make install` SHALL deploy the ECE SDK into `$DESTDIR$PREFIX/` (default `PREFIX=/usr/local`, `DESTDIR` empty), creating `bin/` and `share/ece/` subdirectories.

#### Scenario: Default prefix
- **WHEN** `make install` is run with no overrides
- **THEN** files SHALL be installed under `/usr/local/bin/` and `/usr/local/share/ece/`

#### Scenario: User-prefix install
- **WHEN** `make install PREFIX=$HOME/.local` is run
- **THEN** files SHALL be installed under `$HOME/.local/bin/` and `$HOME/.local/share/ece/`

#### Scenario: Staging install via DESTDIR
- **WHEN** `make install DESTDIR=/tmp/staging PREFIX=/usr/local` is run
- **THEN** files SHALL be installed under `/tmp/staging/usr/local/bin/` and `/tmp/staging/usr/local/share/ece/`

### Requirement: install layout — bin/
The install SHALL place the `ece` binary at `$PREFIX/bin/ece` and create symlinks named `ece-repl`, `ece-build`, `ece-test` in the same directory, each pointing at `ece`.

#### Scenario: bin/ contents after install
- **WHEN** `make install` has completed
- **THEN** `$PREFIX/bin/ece` SHALL be an executable file
- **AND** `$PREFIX/bin/ece-repl` SHALL be a symlink to `ece`
- **AND** `$PREFIX/bin/ece-build` SHALL be a symlink to `ece`
- **AND** `$PREFIX/bin/ece-test` SHALL be a symlink to `ece`

### Requirement: install layout — share/ece/
The install SHALL place ECE runtime files under `$PREFIX/share/ece/`, including: ECE source files needed by tools (`ece-main.scm`, `ece-build.scm`, `ece-test.scm`, `test-lib.scm`), the bootstrap bundle (`bootstrap.ecec`), WASM assets (`runtime.wasm`, `glue.js`, `primitives.json`), and target templates (`templates/cl/`, `templates/web/`).

#### Scenario: share/ece/ contents after install
- **WHEN** `make install` has completed
- **THEN** `$PREFIX/share/ece/bootstrap.ecec` SHALL exist
- **AND** `$PREFIX/share/ece/runtime.wasm` SHALL exist
- **AND** `$PREFIX/share/ece/glue.js` SHALL exist
- **AND** `$PREFIX/share/ece/primitives.json` SHALL exist
- **AND** `$PREFIX/share/ece/templates/web/index.html` SHALL exist
- **AND** `$PREFIX/share/ece/templates/cl/run.sh` SHALL exist
- **AND** `$PREFIX/share/ece/ece-build.scm` SHALL exist
- **AND** `$PREFIX/share/ece/ece-test.scm` SHALL exist

### Requirement: ECE_HOME resolution order
At startup, the `ece` binary SHALL resolve its `ECE_HOME` (the `share/ece/` path) using this order: (1) `$ECE_HOME` environment variable if set and non-empty; (2) `$(dirname argv[0])/../share/ece/` resolved relative to the executable path; (3) a compile-time default. The first existing, readable directory wins.

#### Scenario: ECE_HOME env var override
- **GIVEN** `ece` is at `/opt/ece/bin/ece` and `$ECE_HOME=/custom/share`
- **WHEN** `ece -e "(display (ece-home))"` is invoked
- **THEN** the output SHALL be `/custom/share`

#### Scenario: Binary-relative resolution
- **GIVEN** `ece` is at `/opt/ece-sdk/bin/ece` with `/opt/ece-sdk/share/ece/` present and `$ECE_HOME` unset
- **WHEN** `ece -e "(display (ece-home))"` is invoked
- **THEN** the output SHALL be `/opt/ece-sdk/share/ece`

#### Scenario: Relocatable install
- **GIVEN** the SDK tree is copied from `/opt/ece-sdk/` to `/tmp/moved-sdk/`
- **WHEN** `/tmp/moved-sdk/bin/ece -e "(display (ece-home))"` is invoked
- **THEN** the output SHALL be `/tmp/moved-sdk/share/ece`

### Requirement: make uninstall removes installed files
`make uninstall` SHALL remove the files installed by `make install` at the same `PREFIX`, leaving any other files in `bin/` and `share/` untouched.

#### Scenario: Uninstall after install
- **GIVEN** `make install PREFIX=$HOME/.local` was previously run
- **WHEN** `make uninstall PREFIX=$HOME/.local` is run
- **THEN** `$HOME/.local/bin/ece` SHALL NOT exist
- **AND** `$HOME/.local/bin/ece-repl` SHALL NOT exist
- **AND** `$HOME/.local/share/ece/` directory SHALL NOT exist
