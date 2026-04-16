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

- [x] 2.1 Create `src/scheduler.scm` as a standalone module (not inlined into `ece-serve.scm`). The module exports:
  - `(make-scheduler)` — create a new scheduler instance with an empty fiber table and event-source registry
  - `(scheduler-spawn! sched proc)` — create a new fiber that will run `proc` when next scheduled
  - `(scheduler-step! sched)` — run all currently-ready fibers until none are ready, then return
  - `(scheduler-run! sched)` — loop `scheduler-step!` + poll-events + sleep until interrupted
  - `(wait-for sched event-tag . args)` — used inside a fiber to yield until an event with matching tag arrives; captures the current continuation via `call/cc` and jumps to the scheduler's saved continuation
  - `(scheduler-notify! sched event-tag . args)` — called from outside fibers (e.g. during `poll-events`) to wake any fiber that was waiting on this event tag
  - `(scheduler-register-event-source! sched source-proc)` — add a pluggable event source that the scheduler will call during `poll-events`
- [x] 2.2 Implement the core `call/cc` dance: scheduler captures its own continuation into a per-instance slot (NOT `$yield-continuation` — the scheduler owns its own fiber table), fiber `wait-for` captures its continuation into the fiber table entry and jumps to the scheduler continuation. Test that two fibers can yield and resume independently without interfering.
- [x] 2.3 Implement event tags as generic symbols dispatched through the pluggable event-source registry. The Stage 1 event sources are `'tcp-accept-ready`, `'tcp-read-ready`, `'tcp-write-ready`, `'file-changed`, `'timer-expired`. Adding `'frame-tick` in a future change (per Decision 9) should require no changes to the scheduler core. **Note:** Stage 1 matches on the tag alone — fibers waiting on the same tag all wake together. Per-resource matching (e.g., wait only for reads on a specific socket) can be achieved by using distinct per-resource tags; finer-grained args-based matching is a future refinement if needed.
- [x] 2.4 Document the scheduler's API at the top of `src/scheduler.scm`, including a reference to Dybvig & Hieb's "Engines from Continuations" paper and a note that this module is intentionally designed to subsume the runtime `%yield!` machinery in a future refactor (see design doc Decision 9).
- [x] 2.5 Add unit tests under `tests/ece/common/test-scheduler.scm`: spawn two fibers, verify they interleave correctly, verify event delivery wakes the right fiber, verify a fiber that finishes normally is removed from the table. **Landed:** 13 tests, 46 assertions, covering single-fiber lifecycle, FIFO wakeup ordering, mismatched-tag rejection, scheduler-run! drain, deadlock detection, event sources, mid-run spawning, current-fiber introspection, and wait-for-outside-fiber error path.

## 3. `src/sha1.scm` and `src/base64.scm` — reusable utilities  (**PRE-LANDED via sha1-base64-utilities change**)

- [x] 3.1 Implement SHA-1 in pure ECE. ~170 lines, RFC 3174 conformant, vector-backed block loop for O(1) per-byte access. Landed in the `sha1-base64-utilities` change.
- [x] 3.2 Implement Base64 encoding. RFC 4648 standard alphabet, encoding only, all pad-length cases. Landed in the `sha1-base64-utilities` change.
- [x] 3.3 Unit tests under `tests/ece/common/` for both modules: 5 sha1 tests (RFC 3174 vectors + RFC 6455 intermediate digest), 8 base64 tests (RFC 4648 vectors + end-to-end RFC 6455 handshake check). All passing.
- [x] 3.4 When `ece-serve.scm` is written, add `src/sha1.scm` and `src/base64.scm` to the `share/ece/ece-main.ecec` target's `compile-system` invocation so they're available at runtime (not just in the test-ece target). Done in this PR alongside scheduler / codec / json / ece-serve.scm — single Makefile edit for the whole file list.

## 4. `src/ece-serve.scm` — server logic in ECE

**Protocol codec layer pre-landed via `ece-serve-codecs`:** the HTTP/1.1 parser + response builder is in `src/http-codec.scm` and the RFC 6455 WebSocket handshake + frame codec is in `src/websocket-codec.scm`, both with full unit test coverage. The remaining work for this section is the routing/dispatch layer and the fiber topology that wires the codecs to real sockets through the scheduler.

- [x] 4.1 Create `src/ece-serve.scm` with a top-level procedure `(ece-serve entry-file . opts)` that parses options (`:port`, defaulting to a chosen port), validates that `entry-file` exists, computes the initial watch set, creates a scheduler instance (via `make-scheduler` from `src/scheduler.scm`), and starts the server fibers.
- [x] 4.2 Implement the transitive `(load "...")` walker: read `entry-file` with the ECE reader, find `(load "literal-string")` forms, recursively walk their dependencies, and return the full watch set as a list of absolute paths. Dynamic `(load <expr>)` forms SHALL be ignored for watch-set computation but SHALL NOT cause the walker to fail. Parse errors in a single file are also skipped so a mid-edit source file doesn't kill the walk.
- [x] 4.3 HTTP/1.1 subset parser and response builder — **codec pre-landed as `src/http-codec.scm`**. `http-parse-request` handles the request line, headers (case-insensitive), and the CRLFCRLF terminator; `http-build-response` constructs the status line + headers + body with automatic Content-Length and Connection: close unless overridden. Routing by path (serving `sandbox/index.html` with `ECE_DEV_WS_URL` injection, static files with Content-Type detection) is still TODO and belongs in `src/ece-serve.scm`'s request dispatcher.
- [x] 4.4 WebSocket (RFC 6455) subset — **codec pre-landed as `src/websocket-codec.scm`**:
  - Handshake: `ws-compute-accept-key` computes `base64(sha1(key + magic-guid))` and is verified against the RFC 6455 §1.3 example.
  - Frame encode (server → client): `ws-encode-text-frame`, `ws-encode-close-frame`, `ws-encode-pong-frame` produce FIN+opcode unmasked frames with 7-bit / 16-bit / 64-bit length encoding.
  - Frame decode (client → server): `ws-decode-frame` parses FIN+opcode + MASK+length + mask key + payload, enforces MASK=1 for client frames, rejects fragmentation and unsupported opcodes, demasks via XOR. Tested against the RFC 6455 §5.7 masked text example.
  - **Still TODO in `src/ece-serve.scm`:** the actual upgrade handshake flow (reading the request, building the response with Sec-WebSocket-Accept, transitioning the connection handler fiber to WebSocket mode) and the pong-on-ping logic lives in the server dispatcher, not the codec.
- [x] 4.5 Spawn server fibers on the scheduler:
  - **Accept fiber**: loops calling `tcp-accept-nowait` + `(wait-for sched 'tcp-accept-ready)`. Drains all pending connections per tick, spawns a per-connection handler fiber for each. Guarded so a transient accept error doesn't kill the loop.
  - **Per-connection handler fiber**: reads the HTTP request header block via `read-http-request` (slowloris guard: 1 MiB cap, O(1) byte count), dispatches by method/path. Binary content types (.wasm/.png/.ico) use a byte-list response path separate from the text path so payloads aren't corrupted by character-set decoding.
  - **WebSocket fiber**: hangs waiting for incoming frames; handles close/ping/pong; registers itself in a shared client list so the file-watch fiber can broadcast to it.
  - **File-watch fiber**: calls `fs-watch-start` on the watch set, then waits on `'file-watch-timer` + throttles with `current-milliseconds` to `poll-interval-ms`. For each changed path, broadcasts a source-update message to every registered WebSocket client. Per-client send errors drop the client from the box so dead connections don't accumulate.
- [x] 4.6 JSON encoder for the message envelope: `{type: "source-update", path: "...", source: "..."}`. Landed as `src/json.scm` — handles strings, integers, booleans, null, arrays, and objects with string keys. Full RFC 8259 string escaping for the control range plus `"`, `\\`, `\n`, `\r`, `\t`, `\b`, `\f`. Rejects non-integer numbers explicitly (dev-server envelope doesn't need floats and they introduce formatting ambiguity).
- [x] 4.7 Print the server URL to stdout at startup: `Dev server: http://127.0.0.1:<port>/`. Prints the watch-set size + entry file. Errors inside single broadcast iterations / handler fibers are caught so the server keeps running. No explicit graceful shutdown yet — Ctrl-C drops through `scheduler-run!` and the OS reclaims sockets.

## 5. CLI dispatch and Makefile wiring

- [x] 5.1 In `src/ece-main.scm`, add a dispatch branch for `ece-serve` (argv[0] match) that calls into `ece-serve.scm`'s entry point. Follow the same pattern as existing `ece-repl` / `ece-build` / `ece-test` dispatches.
- [x] 5.2 Update the `compile-system` invocation in `Makefile`'s `share/ece/ece-main.ecec` target so the file list includes `src/scheduler.scm`, `src/http-codec.scm`, `src/websocket-codec.scm`, `src/json.scm`, and `src/ece-serve.scm` alongside the existing SDK files. `sha1`/`base64` already land ahead of scheduler.
- [x] 5.3 Update the `bin/ece` Makefile recipe so it creates `bin/ece-serve` as an additional symlink alongside `bin/ece-repl`, `bin/ece-build`, `bin/ece-test`.
- [x] 5.4 Update the `install` and `uninstall` targets to include `bin/ece-serve` (and all 6 supporting share/ece/ files: scheduler, http-codec, websocket-codec, json, ece-serve, plus sha1/base64 which were missing from install even though they landed earlier).

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

- [ ] 9.1 Run `make test` (full suite: `test-rove test-ece test-wasm test-conformance test-golden test-web-server test-web-apps`). All must pass. **PR B2 status**: test-ece + test-rove + test-wasm run green for the new modules. Pre-existing failures in test-serialization (continuation compactness) and test-source-locations (/tmp sandbox write) are unrelated to ece-serve and visible on main.
- [ ] 9.2 Run `bin/ece build sandbox/programs/starfield.scm --target web --standalone -o /tmp/starfield-build` (or equivalent). Confirm the existing standalone bundle output still works.
- [ ] 9.3 Run `bin/ece repl` and confirm the REPL still starts normally.
- [ ] 9.4 Run `bin/ece test` and confirm it still dispatches correctly.
- [ ] 9.5 Open the sandbox via `file://` with a running existing animation program and confirm `%yield!` / animation-frame flow still works identically — the new scheduler is additive and must not disturb the existing yield machinery.

## 10. Commit and PR

**PR B2 scope note**: This PR lands the server-side dispatcher + fiber topology + json encoder (sections 4.1/4.2/4.5/4.6/4.7 + 5). Browser-side integration (sections 6 + 7) and the full end-to-end manual validation (section 8) are deferred to PR B3 `ece-serve-browser-integration`. The ece-serve openspec change stays active until B3 lands, at which point it's archived in one shot.

- [ ] 10.1 Archive this change in-PR BEFORE merging — **deferred to B3** since sections 6-8 are still pending. The memory rule is "archive a complete change in its final merge PR"; B2 isn't that final PR.
- [ ] 10.2 Commit PR B2 with a message summarizing the scope: `Add ece serve dispatcher + fiber topology (ece-serve PR B2)`.
- [ ] 10.3 Open PR B2. Reference PR #156 (codecs) as the direct predecessor, PR #145 as the Stage 0 predecessor, and cite design doc Decision 9 for the intentional future-proofing of the scheduler module.
