## ADDED Requirements

### Requirement: ece-build script packages web target
`bin/ece-build` with `--target web` SHALL compile .scm files and produce a self-contained directory that runs in a web browser.

#### Scenario: Build a web app
- **WHEN** `bin/ece-build --target web -o dist/ src/main.scm` is run
- **THEN** `dist/` SHALL contain `index.html`, `ece-runtime.js`, `ece-bootstrap.js`, and `app.js`
- **AND** opening `dist/index.html` in a browser SHALL boot ECE and execute the app

#### Scenario: Web output works with file:// protocol
- **WHEN** `dist/index.html` is opened via `file://`
- **THEN** all resources SHALL load without CORS errors
- **AND** all data files SHALL be `.js` files loaded via `<script src>`

#### Scenario: Multiple source files
- **WHEN** `bin/ece-build --target web -o dist/ src/utils.scm src/main.scm` is run
- **THEN** both files SHALL be compiled into the app bundle
- **AND** definitions from `src/utils.scm` SHALL be available to `src/main.scm`

### Requirement: ece-build script packages CL target
`bin/ece-build` with `--target cl` SHALL compile .scm files and produce a self-contained directory runnable with SBCL.

#### Scenario: Build a CL app
- **WHEN** `bin/ece-build --target cl -o dist/ src/main.scm` is run
- **THEN** `dist/` SHALL contain `runtime.lisp`, `bootstrap/`, `app.ecec`, and `run.lisp`
- **AND** `sbcl --load dist/run.lisp` SHALL boot ECE and execute the app

#### Scenario: CL output is self-contained
- **WHEN** `dist/` is copied to another machine with SBCL installed
- **THEN** `sbcl --load dist/run.lisp` SHALL work without the ECE repo present

### Requirement: ece-build resolves ECE_HOME automatically
The script SHALL determine the ECE SDK location relative to its own path, requiring no environment variables or configuration.

#### Scenario: Script run from user's project directory
- **GIVEN** the ECE repo is at `/opt/ece` and the user's project is at `/home/user/myapp`
- **WHEN** the user runs `/opt/ece/bin/ece-build --target web -o dist/ src/main.scm`
- **THEN** the script SHALL find the ECE runtime, bootstrap, and WASM files in `/opt/ece/`

### Requirement: ece-build validates inputs
The script SHALL fail with clear error messages for invalid inputs.

#### Scenario: Missing source files
- **WHEN** a non-existent .scm file is specified
- **THEN** the script SHALL exit with an error naming the missing file

#### Scenario: Missing target flag
- **WHEN** `--target` is omitted
- **THEN** the script SHALL exit with a usage message
