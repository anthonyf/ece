## Context

The ECE sandbox at `sandbox/` runs compiled ECE programs in a browser tab via WasmGC + a canvas element. It includes a REPL (`Sandbox.evalRepl` in `sandbox/sandbox.js`) that lets the user type expressions and evaluate them in the running image, and a Run/Stop button that loads and executes a selected sandbox program (`Sandbox.run`, `Sandbox.stop`).

Animated sandbox programs (starfield, mandelbrot, game-loop, etc.) implement their main loop as a tail-recursive function that calls `(yield)` between frames. `yield` is defined in `src/prelude.scm` as `(call/cc (lambda (k) (%yield! k)))` — it captures the current continuation, and `%yield!` (primitive 150) stores it in `$yield-continuation`, sets `$yield-flag`, and lets the executor return to JS. The JS side (`Sandbox.animationLoop`) then schedules a `requestAnimationFrame` and on each frame invokes `ECE.wasm.call_continuation(contHandle, ...)` to resume the stored continuation for one more frame. This is the cooperative multitasking pattern that makes live coding possible at all — while ECE is yielded, JS is idle and can process REPL input, WebSocket messages, or any other event.

The live-coding workflow this enables in principle:
1. User starts a game loop via Run.
2. While animating, user edits a top-level definition from the REPL (`(set! enemy-speed 5)` or `(define (player-y) 200)`).
3. The REPL eval runs between frames, mutates the global env, next frame picks up the change.
4. If a frame errors, the user fixes the offending definition via the REPL and resumes the loop.

**All the runtime machinery for this already works.** The user has empirically verified that `(set! n 50)` from the REPL during a running starfield takes effect on the next frame without restart. The blockers are two specific gaps in the sandbox's JS-side bookkeeping:

- **Gap 1 — post-crash yield state:** When the animation loop throws (e.g. starfield with `n` set past the vector bounds), `animationLoop()`'s `try/catch` calls `finishRun()`. `finishRun` sets `Sandbox.running = false` but does not call `clear_yield_cont()` / `set_yield_flag(0)`. Compare with `stop()`, which clears both. Result: after a crash, the stale yield state remains in WASM globals, and the next yielding REPL eval interacts with it unpredictably (the user observed `Out of bounds array.get` errors referencing `call_continuation` on subsequent REPL attempts).
- **Gap 2 — REPL evals that yield:** `evalRepl()` calls `call_ece_proc` with `eval-string-last` and then passes the result to `write_val`. If the eval yielded, `call_ece_proc` returns a handle to void (from `%yield!`'s return value), `write_val` prints nothing (rc=1 for void), and control returns to the user with no indication anything happened — and crucially, no one pumps the freshly-stored continuation. Compare with `run()`, which checks `get_yield_flag() || hasYieldCont()` after evaluation and kicks `animationLoop()` if a yield is pending. `evalRepl` has no such check.

These are orthogonal bugs but they manifest together in the "crash → fix → resume from REPL" workflow, which is exactly the live-coding recovery path that must work for the whole browser-dev-loop plan to be worth building.

## Goals / Non-Goals

**Goals:**
- `finishRun()` leaves the WASM runtime in a clean state after a game-loop error, identical to what `stop()` produces.
- `evalRepl()` recognises when a REPL evaluation has resulted in a pending yielded continuation, kicks off the animation loop, and surfaces this to the user via a short feedback message in the REPL output.
- The following crash-and-recover sequence works without reloading the page: run starfield → `(set! n 1000)` → observe out-of-bounds error → `(set! n 100)` → `(draw)` → animation resumes with 100 stars and the correct REPL feedback.
- The existing non-yielding REPL behaviour (arithmetic, variable inspection, defines) continues to work exactly as before, including silent void returns for `(define ...)` and `(set! ...)` forms where the user isn't meant to see output.

**Non-Goals:**
- No changes to the WASM runtime (`wasm/runtime.wat`), ECE kernel, or primitives. This is a JS-only patch.
- No UX redesign of the sandbox (button layout, REPL styling, program picker). The change adds one small feedback line to REPL output; nothing else in the UI changes.
- No attempt to auto-restart a crashed animation loop (e.g. on the user simply redefining a broken function). The user still has to type `(draw)` or equivalent to resume. That "convention-based auto-resume" is a separate concern (the `run-game` convention discussed in the exploration) and belongs in a later change.
- No error handling / debugger work beyond "the runtime is in a clean state so you can recover manually." Catching errors mid-frame, showing structured tracebacks, and wiring errors back to an editor are Stage 5 concerns, not this change.
- No emacs mode, no dev server, no WebSocket. This change is strictly about making the sandbox's existing REPL and animation machinery cooperate correctly.

## Decisions

### 1. Mirror `stop()`'s cleanup logic into `finishRun()` exactly

**Choice:** `finishRun()` will call `ECE.wasm.clear_yield_cont()` and `ECE.wasm.set_yield_flag(0)` as its first two actions, before updating the button UI.

**Rationale:** `stop()` and `finishRun()` should leave the runtime in the same state. `stop()` is a user-initiated clean shutdown; `finishRun()` is called from both the error path in `animationLoop` and the "normal completion" path (when a program finishes without yielding). In both cases, any previously stored yield state is no longer valid and must be cleared. The existence of two "end the run" helpers with different cleanup behaviour is the bug — the fix is to make them converge, not to introduce a third variant.

**Alternatives considered:**
- Add a separate `cleanupYieldState()` helper and call it from both `stop()` and `finishRun()`. Rejected — two extra lines for a helper that's only called twice adds indirection without benefit. The explicit two-line cleanup at the top of each function is clearer.
- Only clear yield state in the error path, not in the normal completion path. Rejected — in normal completion, the yield state is already clear (the program finished without yielding), so clearing it again is a no-op; there's no reason to make the error path special.

### 2. `evalRepl()` checks for pending yield *after* eval, before returning to user

**Choice:** After `call_ece_proc` returns from the eval-string-last call, `evalRepl` checks `ECE.wasm.get_yield_flag() || Sandbox.hasYieldCont()`. If true, it:
1. Sets `Sandbox.running = true`
2. Updates the Run button's text and CSS class to indicate "Stop" (mirroring `run()`)
3. Calls `Sandbox.animationLoop()` to begin pumping frames
4. Appends a feedback line (e.g. `;; yielded — animation resumed`) to the REPL output for that entry

**Rationale:** The two channels for starting a game loop (Run button, REPL) should share the same post-eval dispatch logic. `run()` already has this logic; `evalRepl` is missing it. This decision makes them symmetric: any successful entry point that results in a yielded continuation hands off to the animation loop. The UX feedback line exists because `%yield!` returns void and the default `write_val` path prints nothing for void — without the explicit message, the user has no way to distinguish "my expression ran and returned void" from "my expression started a game loop."

**Alternatives considered:**
- Make `evalRepl` silently kick the animation loop without the feedback line. Rejected — users need positive confirmation that their REPL eval started a loop, especially the first time they use this workflow. The cost (one extra line in the REPL output) is trivial.
- Make `%yield!` return something other than void so `write_val` prints a distinguishable result. Rejected — that's a runtime change for a UX concern that belongs in the sandbox. Also, `%yield!`'s return value is conceptually meaningless (nothing will observe it because the computation has yielded), so giving it a return value just for REPL cosmetics is wrong.
- Factor out the "post-eval yield dispatch" into a shared helper `maybeStartAnimationLoop()` used by both `run()` and `evalRepl()`. Worth considering as a follow-up cleanup but deliberately not part of this change to keep the diff minimal and reviewable. Could be a 1-line follow-up.

### 3. Feedback line format is a Scheme comment

**Choice:** The feedback line appended to the REPL output is a Scheme comment (`;; yielded — animation resumed`), not a quoted string or formatted status.

**Rationale:** Scheme convention — `;;` is universally recognised as a comment and signals "this is metadata, not a return value" to anyone who reads Scheme. It distinguishes sandbox-generated feedback from user-printed output and from eval results. Copy-pasting this into another REPL would make the comment a no-op rather than a syntax error.

**Alternatives considered:**
- Plain text like `yielded — animation resumed`. Rejected — indistinguishable from program output.
- Angle-bracket tag like `<yielded: animation resumed>`. Rejected — looks like an error sentinel and reads oddly in Scheme context.
- A structured object like `(yielded animation-resumed)`. Rejected — overengineered for a UX message.

### 4. No changes to the Run/Stop button's behaviour on click

**Choice:** Clicking Run after a crash still re-runs the full program (current behaviour), and Stop after a REPL-initiated loop still cleanly halts it via the existing `stop()`.

**Rationale:** Neither of these paths is broken — `stop()` already clears yield state correctly, and Run's re-run-from-scratch is the correct recovery when the user wants a fresh start. The fix only targets the two specific gaps that affect live-coded workflows.

## Risks / Trade-offs

- **[Scope creep]** The temptation to fix other sandbox ergonomics at the same time (REPL history, better program picker, error panel, etc.) is real. → **Mitigation**: the change is scoped strictly to the two bugs; unrelated improvements go in separate proposals.

- **[Partial fix leaves a discoverability gap]** With this change, `(draw)` from the REPL works, but the user still has to know to type `(draw)` — there's no "convention" yet for what the main entry is. → **Mitigation**: document the pattern in the change's spec and in the proposal's test plan. Longer-term, a `run-game` convention (tracked as a separate future change) eliminates the need for the user to remember the entry-point name.

- **[Feedback line is English]** The `;; yielded — animation resumed` message is not internationalised. → **Mitigation**: accepted. The sandbox UI has no i18n framework and none of its other UI strings are translated.

- **[Symmetry bug in the other direction]** If a future change adds another entry point for starting a loop (beyond `run()` and now `evalRepl()`), it will need to remember the same post-eval yield check. Easy to forget. → **Mitigation**: factor into a helper (noted as a follow-up). For this change, document the pattern in the design doc so future maintainers can spot the missing call.

- **[Animation state race]** In theory, a REPL eval that yields could land in a moment where `animationLoop` is already running (if the user somehow still has a loop active). → **Mitigation**: not a real risk because after a crash `running` is false and the animation loop is not scheduled. If live coding from the REPL while a loop is already running, the `set! n` path works without going through the yield branch (non-yielding eval, no state change). The yield branch only fires when the user explicitly calls a yielding procedure from the REPL, which means they're starting a new loop intentionally.

- **[Interaction with pre-compiled programs]** The `evalECE` path has a "pre-compiled .ecec first" fallback for programs like Hello World. That path is unrelated to `evalRepl` and unaffected by this change. → **Mitigation**: none needed; documented for completeness.

## Migration Plan

Not applicable. This is a single-file edit with no schema, no migration, and no deployed-state concerns. Rollback is `git revert` on the single commit.

## Open Questions

- **Should the feedback line include a hint about how to stop?** e.g. `;; yielded — animation resumed (click Stop or set! Sandbox.running)`. Probably overkill; the Stop button is already visible. Defer.
- **Should `evalRepl` reset handles + sym cache the way `evalECE` does?** Look at `evalECE` (`w.reset_handles()` + `ECE._symCache = {}` at entry) — the REPL doesn't do this. Might matter for long-running sessions where handles accumulate. Arguably a separate concern from this change, but cheap to add at the same time if it's clearly safe. Decide during implementation.
