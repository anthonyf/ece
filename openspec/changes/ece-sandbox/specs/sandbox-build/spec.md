## ADDED Requirements

### Requirement: Build tooling for file:// compatible bundles
A `make sandbox` target SHALL generate JS files with base64-embedded WASM and .ececb assets, loadable via `<script src>` from `file://`.

#### Scenario: Build and open
- **WHEN** `make sandbox` is run
- **THEN** `sandbox/` SHALL contain all files needed to open `index.html` from the filesystem

### Requirement: No server dependency for development
The sandbox SHALL work by opening `sandbox/index.html` directly in a browser without starting a server.

#### Scenario: Double-click to open
- **WHEN** the user opens `sandbox/index.html` from their file manager
- **THEN** the sandbox SHALL boot and be interactive
