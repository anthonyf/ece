## Why

Stage 0 of the browser-dev-loop plan landed in PR #145 (`sandbox-live-coding-fixes`) — the sandbox can now live-code a running game loop: edit a top-level definition from the REPL, the next frame picks up the change, crashes recover without a page reload. That proved the runtime machinery works end-to-end.

But the workflow still requires typing REPL commands by hand inside the sandbox tab. A real edit-code-in-my-editor-and-watch-the-browser-update loop needs a dev server sitting between the filesystem and the browser:

1. Developer edits `starfield.scm` in emacs (or vscode, or any editor).
2. Dev server notices the file change.
3. Dev server reads the updated source text and pushes it to the browser over WebSocket.
4. Browser calls `eval-string-last` on the received source — the same path the sandbox REPL already uses for live coding — and the running animation picks up the new code on the next frame.

This is Stage 1: `ece serve`. Without it, "live coding" is only usable by someone willing to type directly into the sandbox REPL tab, which is not a realistic workflow for game development. With it, any editor becomes the edit surface and the browser is just the execution/rendering surface — the actual goal of the whole browser-dev-loop initiative.

## What Changes

- **ADDED** `ece serve` subcommand on the existing `ece` CLI binary. Dispatched via argv[0] just like `ece repl`, `ece build`, `ece test`, with a matching `bin/ece-serve` symlink created alongside the others. Usage: `ece serve [path/to/program.scm] [--port 8080]`.
- **ADDED** `src/ece-serve.scm` — the server implementation, written in ECE. Handles CLI arg parsing, HTTP/1.1 request handling (subset: GET for static assets + WebSocket upgrade), WebSocket (RFC 6455 subset: text frames + close), file-watch orchestration, and source broadcasting.
- **ADDED** `src/scheduler.scm` — a standalone cooperative scheduler built on `call/cc`. The dev server runs all its concurrent work (HTTP accept loop, WebSocket clients, file watcher) as fibers on this scheduler. See design doc Decision 8 for details, and Decision 9 for how this module is intentionally positioned to later subsume the sandbox's existing `%yield!` / animation-frame machinery.
- **PRE-LANDED** `src/sha1.scm` and `src/base64.scm` — needed for the WebSocket handshake. Originally in-scope for this proposal but extracted into a dedicated change (`sha1-base64-utilities`, landing ahead of this one) so they can merge independently. When `ece-serve` implementation resumes, these modules are expected to already be on main and just need loading into `share/ece/ece-main.ecec`.
- **ADDED** a narrow set of CL-side primitives wrapping `usocket` (TCP listen / accept-nowait / recv-nowait / send-nowait / close) and a simple file-watch facility (start / poll / stop). All new primitives SHALL be marked platform `cl` in `primitives.def` — they are dev-tooling only and are not portable to WASM. The server logic above is in ECE; only raw socket and filesystem event primitives are added to CL.
- **NO runtime changes** — `%yield!`, `$yield-continuation`, `$yield-flag`, `call-continuation`, and all existing animation-frame machinery stay exactly as they are. The scheduler is additive and runs alongside them without touching the existing yield path. A future proposal (`unify-yield-and-scheduler`) may later subsume `%yield!` into the scheduler, but that is out of scope here.
- **MODIFIED** `sandbox/sandbox.js` — when loaded via `ece serve`, the sandbox SHALL connect to a WebSocket endpoint and handle incoming "source update" messages by calling the existing `eval-string-last` path (the same one `evalRepl` uses). No new evaluation mechanism is introduced; the dev server just drives the existing REPL surface from outside the tab.
- **MODIFIED** `sandbox/index.html` — minimal changes to allow the sandbox JS to know the WebSocket URL (likely via a `window.ECE_DEV_WS_URL` variable injected by `ece serve` when it serves the page).
- **MODIFIED** `Makefile` — add `src/ece-serve.scm`, `src/scheduler.scm` (and ensure `src/sha1.scm` + `src/base64.scm`, already on main by that point, are also present) to the `compile-system` invocation in the `share/ece/ece-main.ecec` target, and add `bin/ece-serve` to the symlinks created by the `bin/ece` recipe.
- **DEPENDENCIES** — one new CL library via qlot: `usocket` (cross-platform TCP). No Hunchentoot, no hunchensocket, no HTTP framework. File watching starts as a polling implementation over `file-write-date`; a native-events library may be evaluated during implementation but is not required.

## Capabilities

### New Capabilities
- `ece-serve` — the dev-server contract: CLI subcommand, HTTP asset serving, WebSocket source broadcast, narrow file-watch scope (`.scm` files in the current program's transitive `(load ...)` closure), whole-file update payloads, and reuse of the existing browser-side `eval-string-last` evaluation path.

### Modified Capabilities
None — no existing capabilities are affected. The sandbox live-coding capability (from PR #145) is extended by adding the WebSocket receive path, but its contract is unchanged: any source received still flows through `eval-string-last`.

## Impact

- **Affected code**:
  - New: `src/ece-serve.scm`, new CL primitives in `src/runtime.lisp` (or a new dedicated file for dev-tool primitives), `bin/ece-serve` symlink
  - Modified: `sandbox/sandbox.js` (WebSocket client, conditional on env), `sandbox/index.html` (WS URL injection), `Makefile` (compile + symlink), `primitives.def` (new primitive entries), `src/ece-main.scm` (subcommand dispatch), `qlfile` (new CL dependencies)
- **Affected workflows**:
  - New: `ece serve path/to/game.scm` → browser opens, editor changes push live
  - Unchanged: `ece repl`, `ece build`, `ece test`, `make ece` all continue to work as before
  - Unchanged: sandbox standalone (loaded from a plain `file://` or static host) continues to work — the WebSocket client SHALL only activate when a WS URL is provided, so no dev-server means no connection attempt
- **Performance**: dev-only. No impact on production builds or runtime performance. CL binary size grows by the new dependency set (likely a few MB of FASLs).
- **Test plan**:
  - Manual: start `ece serve sandbox/programs/starfield.scm`, open the browser to the served URL, confirm animation runs. Edit `starfield.scm` in emacs, change `(define n 100)` to `(define n 50)`, save. Confirm the next animation frame shows ~50 stars without reloading the page or touching the sandbox REPL.
  - Manual: edit a file to introduce a syntax error, save. Confirm the browser receives an error message (in the REPL output area or console), the running animation is NOT crashed, and fixing the file + saving again resumes correctly.
  - Manual: `ece build` and `ece test` still work (no regressions from the Makefile changes).
  - Automated: a smoke test that starts `ece serve` on a test port, connects a headless WebSocket client, sends a trigger, and verifies the browser evaluates the received source. Scope TBD in design.
- **Rollback**: revert the single implementation PR. No schema, no migration, no deployed state. `ece serve` is additive and opt-in.
- **Relationship to the browser-dev-loop plan**: this is Stage 1. Stages 2+ (emacs mode / Geiser polish, error-recovery UX, multi-client support, structured diagnostics) build on top of this but are out of scope for this change.
