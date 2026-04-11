## ADDED Requirements

### Requirement: ece-build script packages web target
`bin/ece-build` with `--target web` SHALL compile .scm files and produce a self-contained directory that runs in a web browser.

#### Scenario: Build with no source files (runtime-only)
- **WHEN** `bin/ece-build --target web -o dist/` is run with a no-op .scm stub
- **THEN** `dist/` SHALL contain `ece-runtime.js` and `ece-bootstrap.js` suitable for use as a base for custom web apps like the sandbox

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

#### Scenario: glue.js has no primitives.json require
- **WHEN** `ece-build` processes `glue.js` for the web target
- **THEN** it SHALL NOT need to strip `require('./primitives.json')` lines
- **AND** `module.exports` SHALL still be stripped for browser use (kept in source for Node.js test harnesses)
- **AND** the `transform-glue-js` function SHALL be replaced by a simpler `strip-module-exports`

## ADDED Requirements (shrink-js-glue)

### Requirement: ece-build test-page target
`ece-build` SHALL support a `--target test-page` option that compiles an ECE test suite and produces a self-contained HTML page with embedded WASM, bootstrap, and test runner.

#### Scenario: Build test page
- **WHEN** `ece-build --target test-page -o dist/ tests/ece/test-*.scm` is run
- **THEN** `dist/` SHALL be a self-contained directory with `index.html` and supporting JS files
- **AND** opening `index.html` in a browser SHALL run the test suite and display results

#### Scenario: Test page replaces build-test-page.sh
- **WHEN** the test page is built via `ece-build --target test-page`
- **THEN** it SHALL produce equivalent output to the former `scripts/build-test-page.sh`
