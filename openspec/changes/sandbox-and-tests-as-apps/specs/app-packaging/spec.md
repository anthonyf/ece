## MODIFIED Requirements

### Requirement: ece-build script packages web target
`bin/ece-build` with `--target web` SHALL compile .scm files and produce a self-contained directory that runs in a web browser.

#### Scenario: Build with no source files (runtime-only)
- **WHEN** `bin/ece-build --target web -o dist/` is run with a no-op .scm stub
- **THEN** `dist/` SHALL contain `ece-runtime.js` and `ece-bootstrap.js` suitable for use as a base for custom web apps like the sandbox
