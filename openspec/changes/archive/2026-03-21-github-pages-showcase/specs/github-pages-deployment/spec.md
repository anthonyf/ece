## ADDED Requirements

### Requirement: Site deploys to GitHub Pages on push to main
A GitHub Actions workflow SHALL build the sandbox, test page, and landing page, then deploy to GitHub Pages on every push to main.

#### Scenario: Push triggers deployment
- **WHEN** a commit is pushed to main
- **THEN** the workflow SHALL build the WASM runtime, sandbox assets, and browser test page, and deploy to GitHub Pages

#### Scenario: Site structure
- **WHEN** the site is deployed
- **THEN** the landing page SHALL be at the root, the sandbox at `/sandbox/`, and the test suite at `/tests/`

### Requirement: Generated sandbox files not committed
The generated sandbox files (`ece-runtime.js`, `ece-bootstrap.js`, `ece-compiled.js`) SHALL be in `.gitignore` and built in CI only.

#### Scenario: Clean repo
- **WHEN** a developer clones the repo
- **THEN** `sandbox/ece-runtime.js`, `sandbox/ece-bootstrap.js`, and `sandbox/ece-compiled.js` SHALL not be present until `make sandbox` is run
