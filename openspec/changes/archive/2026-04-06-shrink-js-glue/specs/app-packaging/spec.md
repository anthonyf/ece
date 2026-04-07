## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: ece-build test-page target
`ece-build` SHALL support a `--target test-page` option that compiles an ECE test suite and produces a self-contained HTML page with embedded WASM, bootstrap, and test runner.

#### Scenario: Build test page
- **WHEN** `ece-build --target test-page -o dist/ tests/ece/test-*.scm` is run
- **THEN** `dist/index.html` SHALL be a self-contained HTML file
- **AND** opening it in a browser SHALL run the test suite and display results

#### Scenario: Test page replaces build-test-page.sh
- **WHEN** the test page is built via `ece-build --target test-page`
- **THEN** it SHALL produce equivalent output to the former `scripts/build-test-page.sh`
