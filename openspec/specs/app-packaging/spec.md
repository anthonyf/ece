## ADDED Requirements

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

## MODIFIED Requirements (shrink-js-glue)

### Requirement: ece-build web target does not depend on primitives.json
`ece-build --target web` SHALL NOT read or inline `primitives.json`. The JS glue layer SHALL NOT contain or require primitive registration data, since primitives are registered by boot-env.ecec during bootstrap.

#### Scenario: Web build without primitives.json
- **WHEN** `ece-build --target web --standalone -o dist/ app.scm` is run
- **THEN** the generated `ece-runtime.js` SHALL NOT contain `ECE_PRIMITIVES` or primitive registration JSON
- **AND** the build SHALL succeed even if `primitives.json` does not exist

#### Scenario: glue.js has no require or module.exports
- **WHEN** `ece-build` processes `glue.js` for the web target
- **THEN** it SHALL NOT need to strip `require('./primitives.json')` or `module.exports` lines
- **AND** the `transform-glue-js` function SHALL be removed from ece-build.scm

## ADDED Requirements (shrink-js-glue)

### Requirement: ece-build test-page target
`ece-build` SHALL support a `--target test-page` option that compiles an ECE test suite and produces a self-contained HTML page with embedded WASM, bootstrap, and test runner.

#### Scenario: Build test page
- **WHEN** `ece-build --target test-page -o dist/ tests/ece/test-*.scm` is run
- **THEN** `dist/index.html` SHALL be a self-contained HTML file
- **AND** opening it in a browser SHALL run the test suite and display results

#### Scenario: Test page replaces build-test-page.sh
- **WHEN** the test page is built via `ece-build --target test-page`
- **THEN** it SHALL produce equivalent output to the former `scripts/build-test-page.sh`
