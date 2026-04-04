## MODIFIED Requirements

### Requirement: ece-build script packages web target
`bin/ece-build` with `--target web` SHALL compile .scm files and produce a directory suitable for web deployment. The default mode produces raw files for HTTP serving. The `--standalone` flag produces self-contained files for `file://` use.

#### Scenario: Default web build (server mode)
- **WHEN** `bin/ece-build --target web -o dist/ src/main.scm` is run
- **THEN** `dist/` SHALL contain `index.html`, `ece-runtime.js`, `runtime.wasm`, `bootstrap.ecec`, and `app.ecec`
- **AND** serving `dist/` over HTTP and opening `index.html` SHALL boot ECE and execute the app

#### Scenario: Standalone web build
- **WHEN** `bin/ece-build --target web --standalone -o dist/ src/main.scm` is run
- **THEN** `dist/` SHALL contain `index.html`, `ece-runtime.js`, `ece-bootstrap.js`, and `app.js`
- **AND** opening `dist/index.html` via `file://` SHALL boot ECE and execute the app

#### Scenario: Multiple source files
- **WHEN** `bin/ece-build --target web -o dist/ src/utils.scm src/main.scm` is run
- **THEN** both files SHALL be compiled into the app bundle
- **AND** definitions from `src/utils.scm` SHALL be available to `src/main.scm`
