## 1. CL dependencies and socket primitive wrappers  (**PRE-LANDED via ece-serve-tcp-fs-primitives**)

- [x] 1.1 Add `usocket` to `qlfile` and pin its version via `qlfile.lock`. Run `qlot install` and confirm it loads into the `ece` ASDF system without regressions.
- [x] 1.2 Add primitive entries to `primitives.def` for the narrow socket + file-watch surface. Every entry MUST have platform `cl`:
  - `tcp-listen` — bind and listen on a TCP port, default host `127.0.0.1`, return server handle
  - `tcp-accept-nowait` — non-blocking accept; return connection handle or `#f`
  - `tcp-recv-nowait` — non-blocking read; return bytevector, `'would-block`, or `'eof`
  - `tcp-send-nowait` — non-blocking write; return bytes-sent or `'would-block`
  - `tcp-close` — close a connection or server handle
  - `fs-watch-start` — begin watching a list of file paths, return watcher handle
  - `fs-watch-poll` — non-blocking poll; return list of paths that changed since last poll
  - `fs-watch-stop` — shut down a watcher
- [x] 1.3 Implement each primitive as a CL function (in `src/runtime.lisp` or a new `src/dev-tools-primitives.lisp` if the runtime.lisp addition would be large). The socket primitives wrap `usocket`; the file-watch primitives start as a polling implementation over `file-write-date` comparisons on the watch set.
- [x] 1.4 Regenerate the bootstrap so new primitive IDs are baked into `primitives-auto.lisp` and the zone files regenerate cleanly. `make bootstrap` and `make ece` must both complete successfully with no CI regressions.

## 2. `src/scheduler.scm` — cooperative scheduler built on `call/cc`

- [ ] 2.1 Create `src/scheduler.scm` as a standalone module (not inlined into `ece-serve.scm`). The module exports:
  - `(make-scheduler)` — create a new scheduler instance with an empty fiber table and event-source registry
  - `(scheduler-spawn! sched proc)` — create a new fiber that will run `proc` when next scheduled
  - `(scheduler-step! sched)` — run all currently-ready fibers until none are ready, then return
  - `(scheduler-run! sched)` — loop `scheduler-step!` + poll-events + sleep until interrupted
  - `(wait-for sched event-tag . args)` — used inside a fiber to yield until an event with matching tag arrives; captures the current continuation via `call/cc` and jumps to the scheduler's saved continuation
  - `(scheduler-notify! sched event-tag . args)` — called from outside fibers (e.g. during `poll-events`) to wake any fiber that was waiting on this event tag
  - `(scheduler-register-event-source! sched source-proc)` — add a pluggable event source that the scheduler will call during `poll-events`
- [ ] 2.2 Implement the core `call/cc` dance: scheduler captures its own continuation into a per-instance slot (NOT `$yield-continuation` — the scheduler owns its own fiber table), fiber `wait-for` captures its continuation into the fiber table entry and jumps to the scheduler continuation. Test that two fibers can yield and resume independently without interfering.
- [ ] 2.3 Implement event tags as generic symbols dispatched through the pluggable event-source registry. The Stage 1 event sources are `'tcp-accept-ready`, `'tcp-read-ready`, `'tcp-write-ready`, `'file-changed`, `'timer-expired`. Adding `'frame-tick` in a future change (per Decision 9) should require no changes to the scheduler core.
- [ ] 2.4 Document the scheduler's API at the top of `src/scheduler.scm`, including a reference to Dybvig & Hieb's "Engines from Continuations" paper and a note that this module is intentionally designed to subsume the runtime `%yield!` machinery in a future refactor (see design doc Decision 9).
- [ ] 2.5 Add unit tests under `tests/ece/common/test-scheduler.scm`: spawn two fibers, verify they interleave correctly, verify event delivery wakes the right fiber, verify a fiber that finishes normally is removed from the table.

## 3. `src/sha1.scm` and `src/base64.scm` — reusable utilities  (**PRE-LANDED via sha1-base64-utilities change**)

- [x] 3.1 Implement SHA-1 in pure ECE. ~170 lines, RFC 3174 conformant, vector-backed block loop for O(1) per-byte access. Landed in the `sha1-base64-utilities` change.
- [x] 3.2 Implement Base64 encoding. RFC 4648 standard alphabet, encoding only, all pad-length cases. Landed in the `sha1-base64-utilities` change.
- [x] 3.3 Unit tests under `tests/ece/common/` for both modules: 5 sha1 tests (RFC 3174 vectors + RFC 6455 intermediate digest), 8 base64 tests (RFC 4648 vectors + end-to-end RFC 6455 handshake check). All passing.
- [ ] 3.4 When `ece-serve.scm` is written, add `src/sha1.scm` and `src/base64.scm` to the `share/ece/ece-main.ecec` target's `compile-system` invocation so they're available at runtime (not just in the test-ece target). Still pending — this is done in ece-serve's implementation PR.

## 4. `src/ece-serve.scm` — server logic in ECE

- [ ] 4.1 Create `src/ece-serve.scm` with a top-level procedure `(ece-serve entry-file . opts)` that parses options (`:port`, defaulting to a chosen port), validates that `entry-file` exists, computes the initial watch set, creates a scheduler instance (via `make-scheduler` from `src/scheduler.scm`), and starts the server fibers.
- [ ] 4.2 Implement the transitive `(load "...")` walker: read `entry-file` with the ECE reader, find `(load "literal-string")` forms, recursively walk their dependencies, and return the full watch set as a list of absolute paths. Dynamic `(load <expr>)` forms SHALL be ignored for watch-set computation but SHALL NOT cause the walker to fail.
- [ ] 4.3 Implement the HTTP/1.1 subset parser/responder in ECE: parse request line (method, path, version), parse headers (`Name: value`), route by path (`/` → serve `sandbox/index.html` with `ECE_DEV_WS_URL` injected; other paths → static files from `sandbox/` with correct `Content-Type` by extension). Response construction writes `HTTP/1.1 <status> <reason>\r\n`, headers, blank line, body. `Connection: close` is the default — no keep-alive in Stage 1.
- [ ] 4.4 Implement the WebSocket (RFC 6455) subset:
  - Handshake: read the `Sec-WebSocket-Key` header, compute `base64(sha1(key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))` using the helpers from section 3, send the 101 response with the computed `Sec-WebSocket-Accept` header.
  - Frame encode (server → client): text frame opcode 0x1, no masking, Content-Length encoded in the standard 7-bit / 16-bit / 64-bit format.
  - Frame decode (client → server): parse FIN+opcode byte, MASK+length byte (MUST have MASK bit set for client frames), read 4-byte mask key, read payload, XOR-demask. Handle text (0x1) and close (0x8) opcodes. Ping/pong (0x9/0xA) — send pong on ping. Fragmentation NOT supported; reject frames with FIN=0.
- [ ] 4.5 Spawn server fibers on the scheduler:
  - **Accept fiber**: loops calling `tcp-accept-nowait` + `(wait-for sched 'tcp-accept-ready server-handle)` when no connection is ready. On a new connection, spawns a per-connection handler fiber.
  - **Per-connection handler fiber**: reads the HTTP request header block (blocking reads via `tcp-recv-nowait` + `wait-for`), dispatches by method/path. For a static asset, writes the response and closes. For a WebSocket upgrade, performs the handshake and transitions the same fiber to a WebSocket message-handling loop.
  - **WebSocket fiber**: hangs waiting for incoming frames; handles close/ping/pong; registers itself in a shared client list so the file-watch fiber can broadcast to it.
  - **File-watch fiber**: calls `fs-watch-start` on the watch set, then loops `fs-watch-poll` + `(wait-for sched 'timer-expired 250)` (or similar throttle). For each changed path, reads the file and broadcasts a source-update message to every registered WebSocket client via that client's fiber.
- [ ] 4.6 JSON encoder for the message envelope: `{type: "source-update", path: "...", source: "..."}`. Either reuse an existing ECE JSON helper (check `src/` first) or add a minimal `src/json.scm` that handles strings, numbers, booleans, arrays, and objects with string keys. String escaping handles `\"`, `\\`, `\n`, `\r`, `\t`, and control characters.
- [ ] 4.7 Print the server URL to stdout at startup: `Dev server: http://127.0.0.1:<port>/`. Print a graceful shutdown message on Ctrl-C. Handle errors defensively: a failed file read (e.g., file transiently missing during an editor rename) logs and continues; a crashed handler fiber is removed from the scheduler without crashing the server.

## 5. CLI dispatch and Makefile wiring

- [ ] 5.1 In `src/ece-main.scm`, add a dispatch branch for `ece-serve` (argv[0] match) that calls into `ece-serve.scm`'s entry point. Follow the same pattern as existing `ece-repl` / `ece-build` / `ece-test` dispatches.
- [ ] 5.2 Update the `compile-system` invocation in `Makefile`'s `share/ece/ece-main.ecec` target so the file list includes `src/scheduler.scm`, `src/sha1.scm`, `src/base64.scm`, and `src/ece-serve.scm` alongside the existing SDK files. Order matters: `sha1` and `base64` before `scheduler` (if the scheduler uses them), `scheduler` before `ece-serve`.
- [ ] 5.3 Update the `bin/ece` Makefile recipe so it creates `bin/ece-serve` as an additional symlink alongside `bin/ece-repl`, `bin/ece-build`, `bin/ece-test`.
- [ ] 5.4 Update the `install` and `uninstall` targets to include `bin/ece-serve` in the symlinks created/removed.

## 6. Browser-side integration

- [ ] 6.1 In `sandbox/sandbox.js`, add a new section `// ── Dev server WebSocket ──` that runs as part of `Sandbox.init()` AFTER `bootECE()`. Check for `window.ECE_DEV_WS_URL`; if present, call a new `Sandbox.connectDevServer(url)` method. If absent, do nothing (standalone behavior unchanged).
- [ ] 6.2 Implement `Sandbox.connectDevServer(url)`: open a WebSocket, attach `onmessage` / `onerror` / `onclose` handlers. On message: parse JSON, dispatch on `type`. For `"source-update"`: call the same code path `evalRepl()` uses (`call_ece_proc` on `eval-string-last` with the received `source` string).
- [ ] 6.3 Factor a small helper out of `evalRepl()` — `Sandbox.evalSource(sourceText)` — that does the shared work (reset handles, call eval-string-last, handle yield, render REPL output). Both `evalRepl()` and the dev-server handler call it.
- [ ] 6.4 On WebSocket error or close, render a brief status line to the REPL output area (`;; dev server disconnected`) and set a flag so the user knows the live loop is no longer active. Auto-reconnect is out of scope for this change.

## 7. `sandbox/index.html` injection point

- [ ] 7.1 In `sandbox/index.html`, add a placeholder `<script>window.ECE_DEV_WS_URL = null;</script>` near the top of `<head>`. Standalone loads see `null` and skip the dev-server client.
- [ ] 7.2 In `ece-serve.scm`'s `/` handler, read `sandbox/index.html`, replace `window.ECE_DEV_WS_URL = null;` with `window.ECE_DEV_WS_URL = "ws://127.0.0.1:<port>/ws";`, and return the modified HTML. A tiny substitution helper is fine; no need for a template language.

## 8. Manual validation

- [ ] 8.1 Start `bin/ece-serve sandbox/programs/starfield.scm --port 8080`. Open `http://127.0.0.1:8080/` in a browser. Confirm the animation starts (either via auto-run or by clicking Run once — document the expected gesture).
- [ ] 8.2 Verify the browser devtools show a WebSocket connection established to `ws://127.0.0.1:8080/ws`.
- [ ] 8.3 In an editor, edit `sandbox/programs/starfield.scm`. Change `(define n 250)` to `(define n 50)`. Save. Confirm within ~500ms the browser animation thins to 50 stars without any manual action in the browser tab and without reloading the page.
- [ ] 8.4 Edit the file to introduce a syntax error (e.g., delete a closing paren). Save. Confirm the browser REPL output area shows an error and the animation continues running with the previous (correct) definitions.
- [ ] 8.5 Fix the syntax error, change something else (e.g., `(define n 100)`), save. Confirm the animation updates again.
- [ ] 8.6 Introduce a runtime error via live coding (e.g., `(set! n 999999)` that blows out the starfield vector bounds). Confirm the browser reports the error via its existing error path, the dev server does not crash, and a subsequent fix + save re-resumes the animation.
- [ ] 8.7 Ctrl-C the server. Confirm it exits cleanly and the browser shows `;; dev server disconnected` in the REPL output area.
- [ ] 8.8 Load `sandbox/index.html` directly via `file://` (standalone). Confirm no WebSocket connection is attempted, no console errors, and the sandbox behaves identically to before this change.

## 9. Regression checks

- [ ] 9.1 Run `make test` (full suite: `test-rove test-ece test-wasm test-conformance test-golden test-web-server test-web-apps`). All must pass.
- [ ] 9.2 Run `bin/ece build sandbox/programs/starfield.scm --target web --standalone -o /tmp/starfield-build` (or equivalent). Confirm the existing standalone bundle output still works.
- [ ] 9.3 Run `bin/ece repl` and confirm the REPL still starts normally.
- [ ] 9.4 Run `bin/ece test` and confirm it still dispatches correctly.
- [ ] 9.5 Open the sandbox via `file://` with a running existing animation program and confirm `%yield!` / animation-frame flow still works identically — the new scheduler is additive and must not disturb the existing yield machinery.

## 10. Commit and PR

- [ ] 10.1 Archive this change in-PR BEFORE merging: run `/opsx:archive ece-serve` on the implementation branch, commit the directory move, include in the same PR. Per the `feedback_archive_before_merge` memory rule, do not merge before archiving.
- [ ] 10.2 Commit with a message summarizing the scope: `Add ece serve dev server with file-watch + WebSocket hot reload`.
- [ ] 10.3 Open PR with the manual test sequence from section 8 as the primary test plan. Reference PR #145 as the Stage 0 predecessor, and cite design doc Decision 9 for the intentional future-proofing of the scheduler module.
