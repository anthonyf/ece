## ADDED Requirements

### Requirement: `tcp-listen` binds and listens on a host:port pair
The `tcp-listen` primitive (id 229, platform `cl`) SHALL accept two arguments — a port integer and a host string — and SHALL return an opaque server handle suitable for passing to `tcp-accept-nowait` and `tcp-close`. The bind SHALL set `SO_REUSEADDR` so a freshly-launched dev server can rebind to the same port without a `TIME_WAIT` delay. When `port` is `0`, the OS SHALL assign an ephemeral port; the assigned port can be retrieved via `usocket:get-local-port` in CL test code.

#### Scenario: Bind to OS-assigned port and accept a connection
- **WHEN** `(tcp-listen 0 "127.0.0.1")` is called
- **THEN** the result SHALL be a usocket server handle
- **AND** `(usocket:get-local-port server)` SHALL return a non-zero port number
- **AND** a subsequent `(tcp-accept-nowait server)` after a client connects SHALL return a connection handle

### Requirement: `tcp-accept-nowait` is non-blocking and returns scheme `#f` when idle
The `tcp-accept-nowait` primitive (id 230, platform `cl`) SHALL accept a server handle and SHALL return either a connection handle (if a client is pending) or the runtime's scheme `#f` sentinel (if no client is pending). The primitive SHALL NEVER block. The check for client readiness SHALL use `usocket:wait-for-input :timeout 0 :ready-only t`.

#### Scenario: Accept on an idle server
- **WHEN** `tcp-accept-nowait` is called on a server with no pending connection
- **THEN** the result SHALL be the runtime's scheme `#f` value
- **AND** `(scheme-false-p result)` in CL SHALL return true

#### Scenario: Accept after a client connects
- **WHEN** a client opens a TCP connection to the server's listen port
- **AND** `tcp-accept-nowait` is then called on the server
- **THEN** the result SHALL be a usocket connection handle (truthy)

### Requirement: `tcp-recv-nowait` distinguishes idle, data, and EOF states
The `tcp-recv-nowait` primitive (id 231, platform `cl`) SHALL accept a connection handle and a `max-bytes` integer, and SHALL return one of:
- a non-empty list of byte integers in `[0, 255]` (length ≤ `max-bytes`) when data is available;
- the symbol `would-block` when no data is currently buffered AND the connection is still open;
- the symbol `eof` when the peer has closed the connection.

The implementation SHALL use `usocket:wait-for-input :timeout 0 :ready-only t` to detect readiness, then distinguish "data ready" from "peer closed" by attempting a single `(read-byte stream nil nil)` and treating a `nil` result as EOF.

#### Scenario: Recv from an idle, open connection
- **WHEN** `tcp-recv-nowait` is called on a connection where the peer has not sent any data
- **THEN** the result SHALL be the symbol `would-block`

#### Scenario: Recv after the peer sent N bytes
- **WHEN** the peer writes 3 bytes (e.g. `65 66 67`) to its end of the connection
- **AND** the kernel has delivered them
- **AND** `(tcp-recv-nowait conn 16)` is then called
- **THEN** the result SHALL be the list `(65 66 67)`

#### Scenario: Recv after the peer closed
- **WHEN** the peer closes its end of the connection without sending any further data
- **AND** the kernel has delivered the FIN
- **AND** `tcp-recv-nowait` is then called
- **THEN** the result SHALL be the symbol `eof`

### Requirement: `tcp-send-nowait` writes a list of byte integers
The `tcp-send-nowait` primitive (id 232, platform `cl`) SHALL accept a connection handle and a list of byte integers in `[0, 255]`, and SHALL write those bytes to the connection in order. The result SHALL be the number of bytes written. Pragmatic implementation note: under typical TCP send-buffer conditions this primitive returns immediately, but it MAY block on a full kernel send buffer; the `would-block` return value is reserved for a future enhancement that switches to a true non-blocking write path.

#### Scenario: Send three bytes
- **WHEN** `(tcp-send-nowait conn '(88 89 90))` is called
- **THEN** the result SHALL be `3`
- **AND** the peer SHALL receive bytes `88 89 90` in order

### Requirement: `tcp-close` releases a server or connection handle
The `tcp-close` primitive (id 233, platform `cl`) SHALL accept either a server handle or a connection handle and SHALL release the underlying OS resources via `usocket:socket-close`. The result SHALL be the runtime's scheme `nil`/`'()` value.

#### Scenario: Close a server handle
- **WHEN** `(tcp-close server)` is called on a previously-listening server
- **THEN** subsequent attempts to bind another server to the same port SHALL succeed without a `TIME_WAIT` delay (because the listen socket used `SO_REUSEADDR`)

### Requirement: `fs-watch-start` snapshots mtimes for a path list
The `fs-watch-start` primitive (id 234, platform `cl`) SHALL accept a list of path strings and SHALL return an integer watcher id. Internally it SHALL record `(file-write-date path)` for each path in a per-watcher hash table.

#### Scenario: Start watching a temp file
- **WHEN** `fs-watch-start` is called with a one-element list `(temp-path)` where `temp-path` exists on disk
- **THEN** the result SHALL be a positive integer watcher id
- **AND** the watcher's stored mtime SHALL equal the file's current `file-write-date`

### Requirement: `fs-watch-poll` returns paths whose mtime advanced
The `fs-watch-poll` primitive (id 235, platform `cl`) SHALL accept a watcher id and SHALL return the list of watched paths whose `file-write-date` has changed since the previous poll for the same watcher. As a side effect, the poll SHALL update the stored mtime for every reported path so that subsequent polls only see new changes.

#### Scenario: Poll immediately after start
- **WHEN** `fs-watch-poll` is called immediately after `fs-watch-start` (before any file modification)
- **THEN** the result SHALL be the empty list

#### Scenario: Poll after a modification
- **GIVEN** a watcher started on a path
- **AND** the file at that path has been rewritten with new content (and the mtime has advanced past the 1-second `file-write-date` granularity)
- **WHEN** `fs-watch-poll` is called
- **THEN** the result SHALL contain that path
- **AND** a subsequent `fs-watch-poll` (with no further modifications) SHALL return the empty list

#### Scenario: Poll on an unknown watcher id
- **WHEN** `fs-watch-poll` is called with a watcher id that was never started or has been stopped
- **THEN** the result SHALL be the empty list (NOT an error)

### Requirement: `fs-watch-stop` discards a watcher
The `fs-watch-stop` primitive (id 236, platform `cl`) SHALL accept a watcher id and SHALL remove the watcher's entry from the internal registry. Subsequent polls on that id SHALL return the empty list as if the watcher had never existed.

#### Scenario: Stop and re-poll
- **WHEN** `fs-watch-stop` is called on an existing watcher id
- **AND** `fs-watch-poll` is called on that same id afterward
- **THEN** the poll result SHALL be the empty list

### Requirement: New primitives are CL-only and not registered for WASM dispatch
All eight primitives (ids 229–236) SHALL be marked platform `cl` in `primitives.def`. They SHALL have no WASM implementation, no entry in `boot-env.scm` (CL builds the global env from the manifest at boot time so explicit registration is not required), and no entry in `wasm/runtime.wat`. An ECE program running under the WASM runtime that attempts to call any of these primitives SHALL receive the standard runtime error message `"Primitive NAME requires cl platform"`.

#### Scenario: Manifest entries
- **WHEN** `primitives.def` is parsed
- **THEN** entries 229 through 236 SHALL exist
- **AND** each entry's platform field SHALL be the symbol `cl`

### Requirement: Codegen regeneration is byte-stable
After the implementation lands, running `make bootstrap/primitives-auto.lisp` SHALL produce a `bootstrap/primitives-auto.lisp` file that is byte-identical to the committed file. This proves the codegen path through `src/primitives.scm` is the canonical source of truth and the hand-bridged step (used to break the chicken-and-egg during initial implementation) is no longer needed.

#### Scenario: Idempotent codegen
- **GIVEN** a committed `bootstrap/primitives-auto.lisp` containing the eight new dev-tooling defuns
- **WHEN** `touch src/primitives.scm && make bootstrap/primitives-auto.lisp` is run
- **THEN** the regenerated file SHALL be byte-identical to the committed file
