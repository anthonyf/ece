## ADDED Requirements

### Requirement: Sandbox loads bootstrap via bundle format
The sandbox SHALL load bootstrap using `ECE.loadEcecBundleText(atob(ECE_BOOTSTRAP_BUNDLE))` instead of iterating per-space `ECE_BOOTSTRAP[name]` entries.

#### Scenario: Sandbox hello world
- **WHEN** a user opens the sandbox and runs the Hello World program
- **THEN** the program executes successfully and displays "Hello, World!"

### Requirement: Test page provides all required WASM imports
The test page SHALL provide `runtime_error` and `trace_save_restore` in the `io` imports object passed to `WebAssembly.instantiate`.

#### Scenario: Test page loads without import errors
- **WHEN** the test page loads in a browser
- **THEN** WASM instantiation succeeds without "must be callable" errors

### Requirement: Test page loads bootstrap via bundle format
The test page SHALL load bootstrap using `ECE.loadEcecBundleText(atob(ECE_BOOTSTRAP_BUNDLE))` instead of iterating per-space `ECE_BOOTSTRAP[name]` entries.

#### Scenario: Test page runs all tests
- **WHEN** the test page loads in a browser
- **THEN** all ECE tests execute and results are displayed
