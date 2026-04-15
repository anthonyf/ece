## Why

The larger `ece-serve` change (Stage 1 of the browser-dev-loop plan) needs a small set of CL-side host primitives so that ECE code can run a TCP server, do non-blocking reads/writes, and watch source files for modifications. The actual server logic (HTTP/1.1 subset, WebSocket framing, fiber scheduler, sandbox integration) is many hundreds of lines of ECE on top of these primitives, but the primitives themselves are:

1. **Foundational and reusable** — any future ECE dev tooling that needs sockets or filesystem events can pick them up. They are not tied to the dev server beyond their original motivation.
2. **Independently complete** — eight primitives, eight unit tests against `usocket` and a temp-file mtime watcher, all green against the existing 143-test rove suite.
3. **Shippable now** — they introduce one new CL dependency (`usocket`, already cross-platform and stable) and require only the standard codegen path through `src/primitives.scm` → `bootstrap/primitives-auto.lisp`. No WASM runtime changes, no bootstrap-program regeneration, no changes to ECE prelude or boot-env.

Rather than land them as part of the much larger `ece-serve` PR (which still has the scheduler, the HTTP/WS handlers, the file-watch driver, the sandbox WebSocket client, and the manual validation matrix), this change extracts the primitive layer into a dedicated proposal so the host-side surface can merge independently. The `ece-serve` proposal is updated in the same PR to mark section 1 of its task list as **PRE-LANDED** via this change, and `ece-serve` continues to ship the scheduler and server logic on top of the now-landed primitives.

This mirrors the pattern used for `sha1-base64-utilities`, the previous `ece-serve` extraction.

## What Changes

- **ADDED** `usocket` as a CL dependency via `qlfile` (pinned through `qlfile.lock`) and `ece.asd` `:depends-on`. The library is small, cross-platform across SBCL on macOS / Linux / Windows, and has been the de facto portable TCP layer for Common Lisp for over a decade.
- **ADDED** eight new manifest entries in `primitives.def` at ids 229–236, all marked platform `cl`:
  - `tcp-listen` (port host) — bind and listen on a TCP port; returns a server handle.
  - `tcp-accept-nowait` (server) — non-blocking accept; returns a connection handle or `#f` when no client is pending.
  - `tcp-recv-nowait` (conn max-bytes) — non-blocking read; returns a list of byte integers, the symbol `would-block` when no data is currently available, or `eof` after the peer has closed.
  - `tcp-send-nowait` (conn bytes) — write a list of byte integers; returns the count written.
  - `tcp-close` (handle) — close a server or connection handle.
  - `fs-watch-start` (paths) — begin watching a list of file paths via mtime polling; returns a watcher id.
  - `fs-watch-poll` (watcher) — return the list of paths whose mtime has changed since the previous poll.
  - `fs-watch-stop` (watcher) — discard a watcher.
- **ADDED** corresponding `define-host-primitive` templates in `src/primitives.scm`. The TCP primitives wrap `usocket` directly; the recv/send and file-watch templates delegate to helper defuns in `src/runtime.lisp` because the bodies are too long for an inline template.
- **ADDED** five helper defuns in `src/runtime.lisp` (`ece-tcp-recv-nowait-impl`, `ece-tcp-send-nowait-impl`, `ece-fs-watch-start-impl`, `ece-fs-watch-poll-impl`, `ece-fs-watch-stop-impl`) plus two module-level specials (`*fs-watchers*`, `*fs-watcher-counter*`) to back the watcher registry.
- **ADDED** five new rove deftests in `tests/ece.lisp`: TCP listen/accept/send/recv round-trip, recv returning `:would-block` on an idle connection, recv returning `:eof` after peer close, fs-watch detecting a modification (sleeps past the 1-second `file-write-date` granularity), and fs-watch-stop discarding the watcher.
- **REGENERATED** `bootstrap/primitives-auto.lisp` from the templates via `make bootstrap/primitives-auto.lisp`. Idempotent regeneration verified.
- **NO new prelude code**, **no new ECE source files**, **no WASM runtime changes**, **no `boot-env.scm` registrations** (CL builds the global env from the manifest at boot time, so no per-primitive registration is needed for CL-only entries).

## Capabilities

### New Capabilities
- `dev-tools-tcp-fs-primitives` — the eight CL-only host primitives the dev server needs. Contract: non-blocking TCP listen/accept/recv/send, plus polling-based file watching, both available to ECE programs running on the CL runtime via the standard primitive dispatch table.

### Modified Capabilities
None. These are pure additions — no existing primitive, helper, or runtime contract is touched.

## Impact

- **Affected code**:
  - New manifest entries: `primitives.def`
  - New templates: `src/primitives.scm`
  - New helper defuns + specials: `src/runtime.lisp`
  - New tests: `tests/ece.lisp`
  - Regenerated: `bootstrap/primitives-auto.lisp`
  - Dependency wiring: `qlfile`, `qlfile.lock`, `ece.asd`
- **Affected workflows**: none — the primitives are opt-in. Code that doesn't reference them is unchanged. The CL global env grows by 8 entries (one per new primitive id), all stub-free because they have CL implementations.
- **Performance**: no impact on existing code paths. The new primitives are dev-tooling only and do not run in the hot ECE evaluation path. The polling fs-watcher uses `file-write-date` mtime comparisons, which is a stat() per polled path — cheap for the dev-loop watch set (typically ≤10 source files).
- **Test plan**: `make test-rove` (148 tests, including 5 new dev-tools tests) + `make test-ece` + `make test-wasm` + `make test` (the full suite: rove, ece, wasm, conformance, golden, server-mode, web-apps). All green except the 3 pre-existing continuation-serialization-size failures, which are unrelated to this change and reproduce on `main`.
- **Rollback**: single-commit revert. Nothing depends on these primitives yet — the `ece-serve` scheduler and server work that will eventually use them is still pending.
- **Relationship to `ece-serve`**: foundational pre-req for sections 2+ of `ece-serve`. The scheduler module (section 2) needs non-blocking I/O primitives to register as event sources; the server logic (section 4) needs them to handle clients. Landing the host-side primitives independently lets the next `ece-serve` PR focus entirely on user-space ECE code.
