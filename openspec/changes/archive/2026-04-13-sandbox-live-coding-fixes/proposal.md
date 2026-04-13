## Why

The sandbox already has all the machinery needed to live-code a running game loop — the WASM runtime supports cooperative yielding via `call/cc` + `%yield!`, the JS animation loop pumps continuations via `requestAnimationFrame`, and the REPL can feed arbitrary source into the running image via `eval-string-last`. But two small JS-side bugs in `sandbox/sandbox.js` prevent the pieces from working together for live coding:

1. After a runtime error in a game loop, `finishRun()` only resets the UI state but leaves `$yield-continuation` and `$yield-flag` set in the WASM runtime, pointing at the dead frame. Subsequent REPL evals that yield behave unpredictably because the stale yield state poisons the runtime's view of "what's waiting to resume."
2. `evalRepl()` never checks whether the expression it just evaluated yielded. If a user types `(draw)` in the REPL, the first frame runs and captures a fresh continuation, but nothing pumps it — the user sees one frame (or, since `%yield!` returns void and `write_val` is silent for void, no REPL output at all) and the animation never actually starts.

Together these gaps mean the sandbox cannot serve as a realistic test of the "edit code while a game runs" workflow that the broader browser-dev-loop plan is built on. Fixing them proves Stage 0 end-to-end and unblocks the rest of the plan.

## What Changes

- **MODIFIED** `sandbox/sandbox.js` — `finishRun()` will call `ECE.wasm.clear_yield_cont()` and `ECE.wasm.set_yield_flag(0)` (matching what `stop()` already does) so that runtime errors in a game loop don't leave the runtime in a half-state.
- **MODIFIED** `sandbox/sandbox.js` — `evalRepl()` will, after its `call_ece_proc` returns, check `ECE.wasm.get_yield_flag()` / `hasYieldCont()`. If a yield is pending, it will set `Sandbox.running = true`, update the Run/Stop button UI, call `animationLoop()` to begin pumping frames, and append a short feedback line (e.g. `;; yielded — animation resumed`) to the REPL output so the user can see their eval started a loop.
- **NO RUNTIME CHANGES** — no modifications to `wasm/runtime.wat`, no new WASM exports, no `primitives.def` changes, no ECE source changes. This is a sandbox-JS-only fix (~10-15 lines total).
- **NO BREAKING CHANGES** — the fixes only activate in situations that were previously broken. Non-yielding REPL evaluation and normal program execution are unaffected.

## Capabilities

### New Capabilities
- `sandbox-live-coding`: The sandbox's contract for live-coding a running game loop from the REPL — state cleanup after errors, automatic resumption of yielded computations evaluated from the REPL, and user feedback for yielded evals.

### Modified Capabilities
None — no existing spec documents the sandbox's live-coding behavior at the requirements level, so this is captured as a new capability rather than a delta.

## Impact

- **Affected code**: `sandbox/sandbox.js` only. Approximately 10-15 lines of added/modified JS.
- **Affected workflows**: The sandbox REPL now supports resuming yielded computations. Running a game loop from the REPL (not just from the Run button) becomes a real workflow. Crash/fix/resume cycles work without reloading the page.
- **Performance**: No measurable change. The new post-eval yield check is a constant-time WASM global read.
- **Test plan**: Manual validation with `starfield.scm`:
  - Run starfield from the Run button, animation works.
  - In REPL: `(set! n 50)` → animation thins to 50 stars, no restart.
  - In REPL: `(set! n 1000)` → out-of-bounds error, animation stops, error shown.
  - In REPL: `(set! n 100)` → void return, no error.
  - In REPL: `(draw)` → ";; yielded — animation resumed" feedback shown, animation picks up with 100 stars, no page reload, no state loss.
  - Hit Stop button, confirm it still cleanly cancels the animation.
- **Rollback**: Single-commit `git revert`. Sandbox-only, no other systems affected.
- **Relationship to the browser-dev-loop plan**: This is Stage 0.5 — the smallest, most self-contained fix that validates the Stage 0 live-coding claim and unblocks later stages (`ece serve`, WebSocket hot reload, emacs mode). This change is standalone and requires no follow-up.
