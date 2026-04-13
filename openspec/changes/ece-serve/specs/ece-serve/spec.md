## ADDED Requirements

### Requirement: `ece serve` is a subcommand on the existing ECE CLI binary
The `ece` CLI binary (built by `make ece`) SHALL expose a new subcommand `serve` that starts a local dev server. The subcommand SHALL be dispatched via `argv[0]=ece-serve` in the same save-lisp-and-die image that hosts `ece repl`, `ece build`, and `ece test`. A `bin/ece-serve` symlink SHALL be created by the `bin/ece` Makefile recipe alongside the existing `bin/ece-repl`, `bin/ece-build`, and `bin/ece-test` symlinks.

#### Scenario: Running `ece serve` starts the server
- **WHEN** the user runs `ece serve sandbox/programs/starfield.scm`
- **THEN** the binary SHALL print a local URL (e.g., `http://127.0.0.1:8080/`) to stdout
- **AND** the binary SHALL continue running until interrupted (Ctrl-C), serving HTTP requests and WebSocket connections on that URL

#### Scenario: `ece serve` is available as a symlink
- **WHEN** `make ece` completes
- **THEN** `bin/ece-serve` SHALL exist as a symlink to `bin/ece`
- **AND** invoking `bin/ece-serve <args>` SHALL be equivalent to invoking `bin/ece serve <args>`

### Requirement: Dev server serves sandbox static assets over HTTP
The server SHALL serve the contents of the `sandbox/` directory (HTML, JS, WASM, compiled bundles, any canvas library assets) over HTTP on the configured port. The root URL SHALL return `sandbox/index.html`. Other static files in `sandbox/` SHALL be reachable under their corresponding paths.

#### Scenario: Browser loads the sandbox from the dev server
- **WHEN** a browser navigates to the root URL printed by `ece serve`
- **THEN** the server SHALL return `sandbox/index.html` with status 200
- **AND** the HTML SHALL reference the same JS/WASM assets as a standalone `file://` load of the sandbox

#### Scenario: Static assets are reachable
- **WHEN** the browser requests `/sandbox.js` (or any other file in the `sandbox/` directory)
- **THEN** the server SHALL return that file's bytes with status 200 and an appropriate `Content-Type` header

### Requirement: Dev server accepts WebSocket connections from browser clients
The server SHALL expose a WebSocket endpoint (distinct from the HTTP asset routes) that browser clients connect to on page load. The server SHALL accept any number of concurrent connections (though one is the expected case) and SHALL broadcast source-update messages to all connected clients.

#### Scenario: Browser opens WebSocket on page load
- **WHEN** the browser loads the HTML served by `ece serve`
- **AND** the HTML has been augmented with the WebSocket URL (via a `window.ECE_DEV_WS_URL` variable or equivalent)
- **THEN** `sandbox.js` SHALL open a WebSocket connection to that URL
- **AND** the server SHALL accept the connection and hold it open for bidirectional messages

#### Scenario: Multiple clients
- **WHEN** two browser tabs both load the dev-server URL
- **AND** both establish WebSocket connections
- **THEN** the server SHALL track both connections
- **AND** subsequent source-update broadcasts SHALL reach both clients

### Requirement: Dev server watches `.scm` files in the program's transitive load closure
On startup, `ece serve <entry-file>` SHALL compute the set of `.scm` files reachable from `<entry-file>` via static analysis of `(load "...")` forms with literal string arguments. The server SHALL watch those files (and the entry file itself) for modification events. Dynamic `(load <expr>)` forms that cannot be statically resolved SHALL NOT expand the watch set automatically in this release.

#### Scenario: Entry file is watched
- **WHEN** `ece serve starfield.scm` starts and the file exists
- **THEN** the watch set SHALL include `starfield.scm`

#### Scenario: Statically loaded dependencies are watched
- **WHEN** `starfield.scm` contains `(load "starfield-utils.scm")`
- **AND** `starfield-utils.scm` exists in the same directory
- **THEN** the watch set SHALL also include `starfield-utils.scm`

#### Scenario: Dynamically loaded files are NOT auto-watched
- **WHEN** `starfield.scm` contains `(load (compute-path))`
- **THEN** the watch set SHALL NOT be extended by the result of `(compute-path)` at analysis time
- **AND** the server SHALL NOT crash on encountering such forms

### Requirement: File modifications trigger whole-file source broadcasts over WebSocket
When any watched file is modified on disk, the server SHALL read the entire file's contents and broadcast a "source update" message over WebSocket to all connected clients. The message SHALL include the file path and the full source text. Partial reads, diff payloads, and incremental patches are explicitly NOT supported in this change.

#### Scenario: File change triggers broadcast
- **WHEN** a watched file is saved with modified content
- **AND** at least one WebSocket client is connected
- **THEN** the server SHALL read the file's new contents
- **AND** SHALL send a source-update message containing the file path and the full source text to each connected client

#### Scenario: Broadcast with no clients connected
- **WHEN** a watched file changes
- **AND** no WebSocket clients are currently connected
- **THEN** the server SHALL NOT crash
- **AND** no error SHALL be reported
- **AND** the server SHALL remain ready to accept future client connections

### Requirement: Browser evaluates received source via the existing `eval-string-last` path
When the sandbox receives a source-update message over WebSocket, `sandbox.js` SHALL call the existing `eval-string-last` procedure (the same one `evalRepl()` uses) with the received source text. No new evaluation mechanism, primitive, or bytecode injection path SHALL be introduced. The sandbox live-coding behaviour (yield state cleanup, REPL output rendering, animation resumption) from the `sandbox-live-coding` capability SHALL apply unchanged.

#### Scenario: Received source is evaluated as if typed into the REPL
- **WHEN** the browser receives a source-update message with source text `(set! n 50)`
- **THEN** `sandbox.js` SHALL call `eval-string-last` on the string `(set! n 50)`
- **AND** the evaluation SHALL flow through the same `write_val` / `yield-check` path `evalRepl()` already uses
- **AND** the running animation (if any) SHALL pick up the change on the next frame

#### Scenario: Received source with a syntax error does not crash the sandbox
- **WHEN** the browser receives a source-update message with source text containing a syntax error
- **THEN** `eval-string-last` SHALL throw or return an error sentinel via its existing error path
- **AND** the error SHALL be rendered in the REPL output area
- **AND** the currently-running animation (if any) SHALL continue running with the previous definitions
- **AND** the WebSocket connection SHALL remain open, ready to receive the next update

### Requirement: Standalone sandbox behavior is unchanged
When the sandbox is loaded outside `ece serve` (e.g., via `file://` or a static HTTP host), it SHALL behave identically to how it behaved before this change. In particular, `sandbox.js` SHALL NOT attempt to open a WebSocket connection when no dev-server URL has been provided.

#### Scenario: Standalone load via file://
- **WHEN** `sandbox/index.html` is opened directly in a browser from the filesystem
- **THEN** `sandbox.js` SHALL detect that `window.ECE_DEV_WS_URL` is not set
- **AND** SHALL NOT attempt any WebSocket connection
- **AND** the sandbox SHALL function exactly as it does today (Run/Stop, REPL, programs dropdown all unchanged)

#### Scenario: Standalone load via static HTTP host
- **WHEN** `sandbox/index.html` is served by an unrelated HTTP server (e.g., `python3 -m http.server`)
- **THEN** the same dormant-WebSocket behavior SHALL apply
- **AND** the sandbox SHALL function exactly as it does today

### Requirement: New CL primitives for HTTP, WebSocket, and filesystem watching are marked platform `cl`
Any new primitives added to implement `ece serve` (wrapping Hunchentoot, hunchensocket, a filesystem watcher, or equivalent host libraries) SHALL be registered in `primitives.def` with the `cl` platform marker. They SHALL NOT have WASM implementations. ECE source code referring to these primitives SHALL fail gracefully on non-CL platforms (either at compile time if the platform is known, or at runtime with a clear "dev-tooling primitive not available on this platform" error).

#### Scenario: Primitive platform marking
- **WHEN** a new primitive is added in `primitives.def` for the dev server
- **THEN** its platform field SHALL be `cl`
- **AND** no corresponding entry SHALL be added to `wasm/runtime.wat`

#### Scenario: WASM runtime does not crash on absent primitive
- **WHEN** an ECE program (e.g., `src/ece-serve.scm`) that references a `cl`-only primitive is loaded in the WASM runtime
- **THEN** the runtime SHALL NOT silently treat the reference as valid
- **AND** invoking the primitive SHALL produce a well-formed error rather than a segfault or arbitrary behaviour

### Requirement: Dev server binds to loopback by default
The HTTP and WebSocket listeners SHALL bind to `127.0.0.1` by default, not `0.0.0.0`. This SHALL prevent the dev server from exposing arbitrary source-text evaluation to the local network out of the box. A command-line option to override the bind address MAY be added later, but it SHALL NOT be the default.

#### Scenario: Default bind
- **WHEN** the user runs `ece serve foo.scm` with no `--host` argument
- **THEN** the server SHALL bind to `127.0.0.1`
- **AND** requests from other machines on the local network SHALL NOT reach the server
