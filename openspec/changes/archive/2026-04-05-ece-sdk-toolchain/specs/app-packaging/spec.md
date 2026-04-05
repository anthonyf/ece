## MODIFIED Requirements

### Requirement: ece-build script packages CL target
`ece-build` with `--target cl` SHALL compile .scm files and produce a self-contained directory runnable via a generated wrapper script that invokes the installed `ece` binary. The generated wrapper SHALL NOT require `sbcl` to be invoked directly by the user.

#### Scenario: Build a CL app
- **WHEN** `ece-build --target cl -o dist/ src/main.scm` is run
- **THEN** `dist/` SHALL contain `app.ecec` and an executable `run` wrapper script
- **AND** executing `dist/run` SHALL invoke `ece` on `app.ecec` and run the app

#### Scenario: CL output uses installed ece binary
- **WHEN** the user has `ece` in `$PATH` and runs `dist/run`
- **THEN** the wrapper SHALL `exec ece "$(dirname "$0")/app.ecec"` (or equivalent)
- **AND** the app SHALL execute without the ECE repo present

#### Scenario: Multi-file CL build
- **WHEN** `ece-build --target cl -o dist/ src/utils.scm src/main.scm` is run
- **THEN** both files SHALL be compiled into `app.ecec`

### Requirement: ece-build resolves ECE_HOME automatically
`ece-build` SHALL determine the ECE SDK location using the same ECE_HOME resolution as the `ece` binary itself: `$ECE_HOME` env var first, otherwise the `share/ece/` directory relative to the `ece` executable path.

#### Scenario: ece-build invoked from installed SDK
- **GIVEN** `ece-build` is a symlink at `/opt/ece/bin/ece-build` pointing to `/opt/ece/bin/ece`
- **WHEN** the user runs `/opt/ece/bin/ece-build --target web -o dist/ src/main.scm`
- **THEN** the tool SHALL find runtime, bootstrap, and WASM files in `/opt/ece/share/ece/`

### Requirement: ece-build validates inputs
`ece-build` SHALL fail with clear error messages for invalid inputs.

#### Scenario: Missing source files
- **WHEN** a non-existent .scm file is specified
- **THEN** the tool SHALL exit with a non-zero code AND an error naming the missing file

#### Scenario: Missing target flag
- **WHEN** `--target` is omitted
- **THEN** the tool SHALL exit with a non-zero code AND a usage message

#### Scenario: Unknown target
- **WHEN** `--target foo` is passed
- **THEN** the tool SHALL exit with a non-zero code AND an error naming the unknown target

## REMOVED Requirements

### Requirement: ece-build script packages web target
**Reason**: This requirement is superseded by the equivalent behavior now provided by the `ece-build.scm` program dispatched via the `ece` binary. The CLI surface (`--target web`, `-o`, positional `.scm` files, `--standalone`) is unchanged — only the implementation moved from a `sh` script at `bin/ece-build` to an ECE program. The web-target output (directory contents, `file://` compatibility) is identical.

**Migration**: Users invoke `ece-build` exactly as before. The binary at `bin/ece-build` is now a symlink to `bin/ece`. The behavior is replaced by equivalent scenarios in `ece-cli` (argv dispatch) and the retained CL-target requirement above.
