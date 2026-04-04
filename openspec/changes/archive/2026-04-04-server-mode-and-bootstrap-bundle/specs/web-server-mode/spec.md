## ADDED Requirements

### Requirement: Server mode produces raw files for HTTP serving
`ece-build --target web` (without `--standalone`) SHALL produce raw .wasm, .ecec, and .js files suitable for serving over HTTP.

#### Scenario: Default web build produces raw files
- **WHEN** `bin/ece-build --target web -o dist/ app.scm` is run
- **THEN** `dist/` SHALL contain `runtime.wasm` (raw WASM binary), `bootstrap.ecec` (raw text), `app.ecec` (raw text), `ece-runtime.js` (JS glue only), and `index.html`
- **AND** `ece-runtime.js` SHALL NOT contain base64-encoded WASM data

#### Scenario: Server mode index.html uses fetch
- **WHEN** `dist/index.html` is opened from an HTTP server
- **THEN** it SHALL load `runtime.wasm` via `WebAssembly.instantiateStreaming()`
- **AND** it SHALL load `bootstrap.ecec` and `app.ecec` via `fetch()`

#### Scenario: Server mode does not work from file://
- **WHEN** `dist/index.html` is opened via `file://`
- **THEN** it SHALL fail due to CORS restrictions on `fetch()`

### Requirement: Server mode integration test
`make test-web-server` SHALL verify the server-mode build pipeline end-to-end.

#### Scenario: Hello world via HTTP
- **WHEN** `make test-web-server` is run
- **THEN** it SHALL compile a hello-world .scm in server mode
- **AND** start `python3 -m http.server` on an OS-assigned port
- **AND** run a Node.js test script that fetches from localhost, boots ECE, and executes the app
- **AND** verify "Hello, World!" appears in the output
- **AND** exit with code 0 on success
