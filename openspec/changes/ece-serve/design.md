## Context

After Stage 0 (PR #145), the sandbox can live-code a running game loop: edits from the REPL tab flow through `eval-string-last`, the ECE runtime yields between frames via `call/cc` + `%yield!`, and the JS animation loop pumps the stored continuation on each `requestAnimationFrame`. The mechanics work. What's missing is a way to drive that REPL surface from outside the sandbox tab — specifically, from whatever editor the developer is actually writing code in.

`ece serve` is the dev server that closes that gap. At runtime it does four things in one process:

1. **Serves the sandbox static assets** over HTTP from a local port (HTML, JS, WASM, .ecec bundles, canvas-lib, etc.). This is basically what `python3 -m http.server` does today when developers want to open the sandbox.
2. **Serves a WebSocket endpoint** that browser clients subscribe to on page load.
3. **Watches the `.scm` files** relevant to the currently-loaded program for modifications.
4. **On a file change, reads the new source text and broadcasts it** as a "source update" message to all connected WebSocket clients.

The browser sandbox, when loaded via `ece serve`, opens the WebSocket, receives update messages, and calls the existing `eval-string-last` path on the received source. This is deliberately the minimum possible browser-side change: the dev server acts as a remote hand pressing "eval" in the REPL, and everything downstream of that is the already-working live-coding path.

Other CLI tools already dispatch via the `ece` binary: `ece repl` starts a REPL, `ece build` builds a bundle, `ece test` runs tests. `ece serve` follows the same pattern — one save-lisp-and-die binary, symlinks per subcommand, argv[0] dispatch.

## Goals / Non-Goals

**Goals:**
- A developer can run `ece serve path/to/game.scm`, open the printed URL in a browser, edit `game.scm` in any editor, and see the running animation pick up the change on the next frame — with no manual action in the browser tab and no page reload.
- The server is implemented in ECE (under `src/ece-serve.scm`) with thin CL primitive bindings for host libraries. No business logic in CL.
- The file-watch scope is narrow and predictable: only `.scm` files transitively reachable from the starting program via `(load ...)`, not the whole project tree.
- Source broadcasts use whole-file payloads. No diff machinery, no incremental patch protocol.
- Reuses the existing browser-side `eval-string-last` REPL path verbatim. The dev server is a thin driver; it does not introduce a new evaluation mechanism or a new hot-reload semantic.
- Error propagation: if the edited file fails to compile, the browser sees the error in its REPL output area (same rendering path as manual REPL errors), and the running animation is NOT killed — the old definitions remain in place until the file compiles again.

**Non-Goals:**
- Emacs mode / Geiser integration. Stage 2 / 3 territory — this change is explicitly editor-agnostic.
- Error-recovery UX improvements beyond "show the error, don't crash." Structured tracebacks, clickable source locations, and reload-on-fix are Stage 5.
- Multi-client / multi-project support. Stage 1 serves exactly one program at a time; one browser client is the expected case, though more may work by accident.
- Diff-based / incremental updates. Whole-file is simpler to reason about and robust against partial edits. Only revisit if whole-file is measurably too disruptive to running state.
- Production / deployment server. `ece serve` is dev-only. The existing `ece build --target web` command still produces shippable standalone bundles.
- New runtime primitives for ECE game code. The dev server adds CL-side primitives for host-side dev tooling (HTTP, WebSocket, fswatch), not new ECE game runtime.

## Decisions

### 1. `ece serve` is a subcommand on the existing CLI binary

**Choice:** A new subcommand dispatched via `argv[0]=ece-serve` on the existing `ece` save-lisp-and-die binary, with a `bin/ece-serve` symlink created by the `bin/ece` Makefile recipe. Same model as `ece repl`, `ece build`, `ece test`.

**Rationale:** The `ece` binary is already the "launchpad for different tools" (user's words). A second binary would double the SBCL startup cost for dev workflows, duplicate the ASDF load path, and fragment the user-facing surface. Sharing the image also means `ece serve` has direct access to the ECE compiler, reader, and runtime for server-side syntax checking if that becomes useful later.

**Alternatives considered:**
- A separate `ece-serve` Lisp script invoked independently. Rejected — doubles startup cost, fragments tooling, and forces developers to install a second binary.
- A Node.js or Python dev server. Rejected — violates "prefer ECE over host languages," and every host-language dev server in the world is a layer of translation away from what we actually want, which is "reuse the existing browser's `eval-string-last` path."

### 2. Whole-file updates, not diffs

**Choice:** On file change, the server reads the entire file and broadcasts the full source text. The browser evaluates the whole file via `eval-string-last`.

**Rationale:** Whole-file is simpler to reason about, robust against any kind of edit (multi-line changes, reorders, comment-only changes, new top-level forms), and matches how a Scheme programmer already thinks about "(load ...) this file again." Diff-based updates require tracking previous file state, detecting top-level form boundaries, and handling edge cases (name changes, moved definitions, macro expansion state). That complexity isn't needed for the core workflow.

**Tradeoff:** whole-file re-evaluation re-runs all top-level initializer code every time, which for some programs means re-creating hash tables or re-initializing global state. The user can write programs defensively against this (use `set!` instead of re-`define`, guard initializers with "only if not already defined") — that's already good practice for live coding. If re-evaluation causes real pain in practice, diff mode becomes a follow-up proposal.

**Alternatives considered:**
- **Diff mode (top-level form granularity).** Rejected as default for this change; keep as a future option if pain materializes.

### 3. Narrow file-watch scope

**Choice:** Watch only the `.scm` files transitively reachable from the starting program via `(load ...)` forms, not the whole `src/` tree or the project root.

**Rationale:** A game's working set is small (its own `.scm`, maybe a few helper modules), and the developer's edit loop cares about those. Watching the whole project tree means spurious events from `.git`, `.tmp`, editor autosave files, build artifacts — none of which should trigger a browser reload. Narrow scope also means the dev server never accidentally reloads `src/prelude.scm` and invalidates the running image.

**Tradeoff:** if the user edits a file outside the watch set, the browser doesn't pick it up until they load-the-entry-file-again. That's an acceptable limitation for the first cut. If transitive closure analysis proves fragile (e.g., dynamic `(load)` calls), the design can fall back to an explicit file list supplied on the command line.

**Alternatives considered:**
- **Watch project root recursively.** Rejected — spurious events, unbounded scope, editor noise.
- **Let the user supply a list of files via `--watch foo.scm --watch bar.scm`.** Considered as a fallback if transitive closure detection is too flaky. Cheap to add later.

### 4. HTTP/1.1 and WebSocket implemented from scratch in ECE on minimal socket primitives

**Choice:** Rather than wrap a mature HTTP library (Hunchentoot) and WebSocket library (hunchensocket) via many primitives, the server implements an HTTP/1.1 subset and WebSocket (RFC 6455) protocol handlers entirely in ECE. The CL primitive surface is narrow — roughly six socket operations — wrapping a thin library such as `usocket` for cross-platform TCP plus a small file-watching primitive. SHA-1 and Base64 (required for the WebSocket handshake) live in `src/sha1.scm` / `src/base64.scm` and **are pre-landed by a separate change** (`sha1-base64-utilities`); `ece-serve.scm` just loads them.

**Rationale:** The "prefer ECE over host languages" feedback rule applies hard here. Wrapping Hunchentoot requires exposing HTTP request routing, response construction, header parsing, static file serving, and stream lifecycle as primitives — a large surface area that's effectively "the HTTP library, but re-exported." That's backwards: we'd be authoring a thick CL shim to then invoke from a thin ECE wrapper. From-scratch inverts the ratio — most of the code is in ECE, and the CL kernel additions are strictly "give ECE raw sockets and file-watch events." Other benefits:
- **SHA-1 and Base64 are reusable ECE utilities** once written, valuable for future crypto/encoding work independent of `ece-serve`.
- **Far smaller CL dependency footprint** — `usocket` is a small, stable library compared to the Hunchentoot stack.
- **Dogfoods the language on real protocol code** — parsing, state machines, binary framing.
- **Better portability path long-term** — if ECE ever runs under WASI in a non-browser context, WASI sockets give the same semantics, and the from-scratch code ports directly.

**Tradeoff:** more ECE code to write and maintain (roughly 1000 lines vs. ~400 lines for a library-wrapping version). Edge cases in HTTP and WebSocket specs are a rabbit hole (chunked transfer encoding, fragmentation, ping/pong, close handshake). We accept this by implementing only the subset this dev server needs — we control both ends of the connection (our HTTP server and our sandbox WebSocket client), so there's no third-party interop burden. Anything outside the subset is documented as "not supported, file an issue."

**Primitive surface (CL-side):**
- `(tcp-listen port [host])` → server handle, bound to `127.0.0.1` by default
- `(tcp-accept-nowait server)` → connection handle or `#f` (non-blocking; blocking is intentionally not offered because the scheduler is non-blocking — see Decision 8)
- `(tcp-recv-nowait conn max-bytes)` → bytevector, `'would-block`, or `'eof`
- `(tcp-send-nowait conn bytes)` → number of bytes written, or `'would-block`
- `(tcp-close conn)`
- `(fs-watch-start paths)` → watcher handle
- `(fs-watch-poll watcher)` → list of changed paths since last poll
- `(fs-watch-stop watcher)`

All primitives are marked platform `cl` in `primitives.def` and have no WASM implementations. They're dev-tooling only and intentionally not portable.

**Alternatives considered:**
- **Wrap Hunchentoot + hunchensocket** — rejected, as above: large CL shim surface, inverts the "prefer ECE" ratio, library bloat.
- **Wrap Clack (more modern, more abstraction)** — same objection, different library.
- **Write `ece serve` as a CL source file in `src/`** — rejected, violates the "prefer ECE" rule, and we've done the primitive-binding pattern successfully for existing SDK tools.

### 5. Browser reuses `eval-string-last` verbatim

**Choice:** The browser-side WebSocket client receives source text messages and calls `w.call_ece_proc(evalStringLastProc, sourceString)` — literally the same call `evalRepl()` already makes in `sandbox/sandbox.js`. No new evaluation path, no new protocol, no bytecode injection.

**Rationale:** The sandbox's REPL-yield-resume mechanics are validated (PR #145). Any new evaluation path would have to re-prove those mechanics. Reusing the REPL path means the dev server gets crash recovery, yield resumption, and the feedback-line UX for free.

**Tradeoff:** the feedback line `;; yielded — animation resumed` will show up in the REPL output area every time a file change triggers a re-eval that restarts the animation loop. That might feel chatty. If it does, the browser-side handler can suppress the feedback specifically for dev-server-sourced evals, but not in this change.

**Alternatives considered:**
- **A dedicated `apply-source-update` function that bypasses the REPL output UI.** Rejected — adds a parallel code path that duplicates REPL semantics without benefit.

### 6. Source distribution: server injects WebSocket URL into `index.html`

**Choice:** When `ece serve` serves `sandbox/index.html`, it injects the WebSocket URL into a `<script>` tag or a query parameter on the page. The existing `sandbox.js` checks for that variable on boot and, if present, opens the WebSocket. If absent (standalone sandbox load via `file://`), the WebSocket client is dormant and the sandbox behaves exactly as it does today.

**Rationale:** keeps the sandbox HTML unchanged for the standalone case. The dev server is the only thing that introduces the WS URL, so the standalone workflow is unaffected. Simple conditional in `sandbox.js`: "if `window.ECE_DEV_WS_URL` is set, connect; otherwise, don't."

**Alternatives considered:**
- **Always try to connect to a default localhost port.** Rejected — adds a reliable console error when standalone sandbox loads, and hardcodes a port.
- **Serve a different HTML file when `ece serve` is running.** Rejected — more files to maintain, more drift potential.

### 7. Error handling: show, don't crash

**Choice:** If a file fails to compile or evaluation throws during a received source update, the server sends an error message that the browser renders in the REPL output area. The running animation loop (if any) is NOT interrupted — the existing definitions remain in place. The user fixes the file, saves, and the next successful update replaces the broken definitions.

**Rationale:** Live coding is fundamentally about tolerating transient broken states. Crashing the animation on every typo would be worse than the current sandbox-REPL workflow. The user wants to stay in the running-game state and iterate.

**Tradeoff:** if a file change introduces a *semantic* error that doesn't immediately crash (e.g., a wrong formula) the animation shows visibly wrong behavior — but that's the point of live coding. The developer sees the wrong result, corrects it, saves again.

### 8. Cooperative multitasking via `call/cc` in a standalone scheduler module — no threads

**Choice:** The dev server handles multiple concurrent fibers (HTTP requests, WebSocket clients, file-watch events) via a cooperative scheduler written entirely in ECE. The scheduler lives in its own module `src/scheduler.scm`, built on first-class continuations (`call/cc`). Fibers explicitly yield by calling blocking-looking primitives that internally register "waiting for event X" with the scheduler and capture their continuation. The scheduler picks the next ready fiber on each tick. **No OS thread primitive is added to the language.**

**Rationale:** Threads would be genuinely bad for the runtime:
- The register-machine state (`pc`, `val`, `env`, `proc`, `argl`, `continue`, `stack`) is single-threaded. Making it thread-safe means per-thread copies and locking, which bleeds into the hot path.
- `*global-env*`, `*compile-time-macros*`, `*compiled-zone-functions*`, port tables, hash-table literals — all shared state with no concurrency story. A concurrent `define` or `set-macro!` would race.
- The WASM build has no OS threads at all. A thread primitive bifurcates the language between CL and WASM targets.
- `call/cc` is already hard enough to reason about single-threaded; concurrent captures and resumes on a shared runtime is a minefield.

`call/cc`-based cooperative scheduling avoids all of this. Single-threaded runtime stays single-threaded. Concurrency is user-level, not runtime-level. The primitive requirement is satisfied by the same `call/cc` we already use for `%yield!` today. The pattern is well-established — **Dybvig & Hieb's "Engines from Continuations" (1989) is the canonical reference** for building preemptive/cooperative multitasking purely in Scheme via first-class continuations, and what we're building here is structurally an engine per fiber with a scheduler loop on top.

**Sketch:**

```scheme
(define (scheduler-step)
  (let loop ()
    (call/cc
      (lambda (k)
        (set! *scheduler-k* k)
        (let ((fiber (find-ready-fiber)))
          (when fiber
            (set! *current-fiber* fiber)
            (resume-fiber fiber)))))
    (if (find-ready-fiber) (loop) 'done)))

(define (wait-for event-tag . args)
  (call/cc
    (lambda (fk)
      (set-fiber-continuation! *current-fiber* fk)
      (set-fiber-waiting-on! *current-fiber* (cons event-tag args))
      (*scheduler-k* 'fiber-yielded))))
```

A fiber reads as if I/O were blocking; under the hood each blocking primitive calls `wait-for` whenever a non-blocking read returns `'would-block`. The scheduler's `find-ready-fiber` consults the poll results from `fs-watch-poll` and `tcp-accept-nowait` / `tcp-recv-nowait` to decide which fibers are ready.

**Tradeoffs:**
- Cooperative scheduling means a single misbehaving fiber (infinite loop, tight CPU spin) can starve the others. For a dev server this is acceptable — we don't run untrusted code. If starvation becomes a real problem later, engines-with-fuel is a known extension.
- Debugging continuation flow is harder than debugging thread flow for developers unfamiliar with `call/cc`. Mitigation: keep the scheduler small, well-commented, and isolated in its own module.

**Alternatives considered:**
- **OS threads via a `spawn-thread` primitive.** Rejected as above — incompatible with the runtime's single-threaded assumptions and with WASM.
- **Event loop with explicit state machines (no `call/cc`).** Rejected — each fiber would have to be manually re-chunked into state-machine steps, which is how Node.js callbacks used to look before `async/await`. Clunky to write and hard to follow in a Scheme context.
- **Combine the scheduler with the existing `%yield!` / `$yield-continuation` mechanism.** Considered but deferred — see "Future Direction" below.

### 9. Future Direction: the scheduler is a step toward eliminating `%yield!` from the runtime

**Non-goal for this change, but design-mandated for consistency:** the scheduler module built here should be designed so that, in a future proposal, it can subsume the sandbox's existing `%yield!` / `$yield-continuation` / `$yield-flag` machinery and render them unnecessary in the runtime.

**The architectural picture:** today, `%yield!` exists as a runtime primitive only because the sandbox's JS side needs a well-known slot to reach into a running ECE computation and pull out its continuation between animation frames. It's an ad-hoc bridge, not a language feature — three runtime globals (`$yield-continuation`, `$yield-flag`, and the WASM exports that read/write them) exist to let a specific outer driver poke at a specific piece of state.

In a scheduler-based world, that whole pattern inverts. Instead of "ECE runs in an infinite loop until it yields a continuation out to JS," the outer driver (`requestAnimationFrame` callback in the browser, or `ece serve`'s main loop on the host) calls `(scheduler-step)` as a normal procedure. `scheduler-step` runs ready fibers, handles yields via `call/cc` internally, and returns when it runs out of work. No runtime globals. No early-exit flag. No well-known continuation slot. Just first-class continuations passed around as values and stored in the scheduler's own fiber table.

Specifically, the future simplification would:
1. Reimplement `(yield)` in `src/prelude.scm` as `(scheduler-wait-for 'frame-tick)`, using the scheduler's general event-tag machinery.
2. Modify `sandbox/sandbox.js`'s animation loop to, on each `requestAnimationFrame`, call a WASM export like `(scheduler-notify! 'frame-tick)` then `(scheduler-step)` — instead of today's direct `call_continuation` path.
3. Delete the `%yield!` primitive, the `$yield-continuation` and `$yield-flag` globals, and their `get_yield_cont` / `set_yield_flag` / `call_continuation` WASM exports. The runtime becomes the register machine plus `call/cc`, nothing else.

**What Stage 1 (this change) does to enable that:**
- The scheduler is written as a **standalone module** `src/scheduler.scm`, not inlined into `src/ece-serve.scm`. The server uses it; later, `prelude.scm` can use it too without code motion.
- The scheduler's API is **`(wait-for event-tag [args...])`**, not `wait-for-socket-read` or `wait-for-frame`. Event tags are symbols dispatched generically; adding `'frame-tick` later is a one-line change in the prelude.
- Fiber continuations live in **the scheduler's own data structure** (a hash or vector), not in any runtime global. Nothing in `src/scheduler.scm` uses `%yield!` or `$yield-continuation` directly — the existing runtime yield machinery is untouched by this change and runs in parallel with the scheduler during Stage 1.
- Event sources (socket readable, file-watch change, timer) are **pluggable** — the scheduler's `poll-events!` function walks a list of registered event sources. A future change adds "frame-tick signal" as another event source without touching the scheduler's core.

**What Stage 1 does NOT do:**
- Does NOT touch `src/prelude.scm`'s `(yield)` / `(call/cc (lambda (k) (%yield! k)))`.
- Does NOT touch `wasm/runtime.wat`'s yield-flag / yield-continuation handling.
- Does NOT touch `sandbox/sandbox.js`'s `animationLoop`.
- Does NOT modify any existing sandbox program.

Keeping both mechanisms alive in parallel during Stage 1 means zero risk to the existing live-coding capability that PR #145 just landed. The unification work is a separate future proposal (call it `unify-yield-and-scheduler`) that will need its own investigation: running-image migration, sandbox program regressions, WASM runtime surgery, and so on. Leaving room in Stage 1's design for that work is free; doing the refactor now would blow up the scope.

**SICP connection:** nothing in this design is ad hoc. The register machine is Chapter 5. `call/cc` is covered in Chapter 4's exercises. Continuation-passing style (Chapter 4.1 analyzer) is the substrate. What we're calling "fiber" is Dybvig & Hieb's "engine from continuations." The refactor direction is moving ECE's runtime *closer* to the SICP model, not away from it — the current `$yield-continuation` global is a pragmatic bolt-on that we'd be pleased to delete.

## Risks / Trade-offs

- **[From-scratch protocol implementation complexity]** Writing HTTP/1.1 and WebSocket from scratch (even as subsets) is more ECE code than wrapping mature libraries, and has more surface area for bugs in parsing, framing, and state machines. → **Mitigation**: explicitly scope to the subset this dev server needs. We control both ends (our server, our sandbox client), so we don't need third-party interop — anything outside the subset is "not supported." SHA-1 and Base64 get minimal, well-tested implementations. Document the HTTP + WebSocket subset in comments at the top of each module.
- **[Cross-platform TCP sockets]** `usocket` is portable across SBCL on Linux, macOS, and Windows — but the non-blocking accept / recv / send semantics can vary subtly. → **Mitigation**: build on `usocket`'s portable API surface (`socket-listen`, `socket-accept`, `socket-stream` + `listen` / `read-sequence` / `write-sequence`). Polling with `listen` + a read-or-nothing pattern is portable. Validate on Linux CI and macOS locally during implementation.
- **[Cross-platform file watching]** `inotify` is Linux-only; macOS uses `fsevents`; Windows uses `ReadDirectoryChangesW`. A portable CL library may not exist or may have rough edges. → **Mitigation**: start with a polling-based watcher (cross-platform, simple, wastes some CPU but works everywhere) backed by `file-write-date` comparisons on the watch set, and consider native event sources as a follow-up optimization. Polling every 250-500ms is fine for an interactive dev loop.
- **[Transitive `(load ...)` detection is fragile]** ECE's `load` can take a dynamically-computed path, so static analysis can't always determine the watch set. → **Mitigation**: start with `(load "...literal path...")` form detection only, and fall back to "watch only the entry file" if the analysis can't resolve. Document as a known limitation. User can supply `--watch` explicitly as an escape hatch.
- **[Whole-file re-eval disrupts running state]** Some programs re-initialize global state on every load. → **Mitigation**: this is an existing concern of live coding; document in the proposal and in `ece-serve.scm`'s usage help. If it becomes a real problem, diff mode is a known follow-up.
- **[Cooperative scheduler starvation]** A misbehaving fiber (infinite loop, tight CPU spin) starves the others and freezes the dev server. → **Mitigation**: document as a known limitation. For Stage 1 the server runs only our own code, not user code from the browser side, so starvation risk is internal. Engines-with-fuel is a known future extension if it becomes a problem.
- **[WebSocket connection lifecycle with the Run/Stop button]** What happens if the user clicks Stop? Click Run? Click Stop again? The dev server's file-change events continue firing regardless of button state. → **Mitigation**: broadcast events regardless; `Sandbox.running` state is orthogonal. If the user clicks Stop, a subsequent file-change-triggered eval will start a new animation loop (via the existing `evalRepl` yield-resume path). Document this as expected behavior.
- **[Security]** `ece serve` binds an HTTP + WebSocket port and hands the browser arbitrary source-text evaluation. Anyone else who can reach the port can evaluate arbitrary ECE code in the running browser image. → **Mitigation**: bind to `127.0.0.1` by default, not `0.0.0.0`. Document that `--host 0.0.0.0` (if added later) exposes the dev loop to the local network and should only be used intentionally. This is the standard dev-server threat model.
- **[Stage 1 locks in implementation decisions for Stage 2+]** Choices made here (WebSocket protocol, message format, file-watch scope, scheduler API) become the starting point for the emacs mode and Geiser-style integration in later stages, and for the eventual `unify-yield-and-scheduler` refactor. → **Mitigation**: keep the wire protocol simple (source-text + optional file-path metadata in a small JSON envelope), keep the scheduler API tag-based and pluggable (per Decision 9), and document both explicitly so later changes can reference them.

## Migration Plan

Not applicable. `ece serve` is additive, opt-in, dev-only. Nothing existing is deprecated or changed. No data migration, no API version bump.

## Open Questions

- **Socket library:** `usocket` is the default assumption — small, portable, well-maintained. Is there a reason to prefer a different TCP library or to write the socket primitives with lower-level SBCL-specific APIs (`sb-bsd-sockets`)? Decide during implementation; default to `usocket` unless a concrete issue surfaces.
- **File watcher library:** polling via `file-write-date` is the simple default. Investigate `cl-inotify` or `trivial-file-watch` during implementation; decide based on portability and API cleanliness. Polling is the fallback if nothing clean exists.
- **Scheduler event-source registration API:** how pluggable should event sources be in the Stage 1 scheduler? Minimal = hard-coded `poll-events!` that calls `tcp-accept-nowait` / `tcp-recv-nowait` / `fs-watch-poll`. Maximal = fully pluggable event-source table so Decision 9's future refactor doesn't have to touch the scheduler's core. Lean toward pluggable from day one since it's not much extra code.
- **SHA-1 / Base64 location:** resolved — standalone modules at `src/sha1.scm` and `src/base64.scm`, pre-landed by the `sha1-base64-utilities` change. `ece-serve.scm` just calls into them.
- **Port configuration:** default port. 8080? 4005 (Swank's default, might clash)? 7777? Pick something unlikely to clash.
- **Message protocol:** source-update is an obvious message type. Should the server also send "file-saved-but-syntax-error" messages, or let the browser's own `eval-string-last` discover the error? Lean toward the latter to keep the server dumb.
- **CLI argument format:** `ece serve <file>` is obvious, but what about `--port`, `--host`, `--watch <extra-file>`? Decide during implementation — probably just `--port` for this first cut.
- **Program dropdown in the served sandbox:** when the server is pointed at a specific `.scm`, should the sandbox dropdown still show all sandbox/programs entries, or only the served file? Lean toward "only the served file" so the dev loop is unambiguous. Decide during implementation.
