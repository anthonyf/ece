## 1. Fix `finishRun` yield-state cleanup

- [x] 1.1 In `sandbox/sandbox.js`, modify `Sandbox.finishRun()` to call `ECE.wasm.clear_yield_cont()` and `ECE.wasm.set_yield_flag(0)` before its existing `Sandbox.running = false` line (mirror the first three lines of `Sandbox.stop()`)
- [x] 1.2 Verify by inspection that `stop()` and `finishRun()` now produce identical WASM state cleanup
- [x] 1.3 Manual test: run `starfield.scm`, trigger the crash with `(set! n 1000)`, then from the browser devtools console confirm `ECE.wasm.get_yield_flag()` returns 0 and `ECE.wasm.get_yield_cont()` returns a null/nil handle

## 2. Fix `evalRepl` to resume yielded computations

- [x] 2.1 In `sandbox/sandbox.js`, modify `Sandbox.evalRepl()` so that after the `call_ece_proc` line (and after `write_val` has rendered any non-void result), it checks `ECE.wasm.get_yield_flag() || Sandbox.hasYieldCont()`
- [x] 2.2 If a yield is pending, set `Sandbox.running = true`, update `#run-btn`'s text to `"\u25A0 Stop"` and add the `"stop"` CSS class (matching `run()`'s button update), then call `Sandbox.animationLoop()`
- [x] 2.3 If a yield is pending, append a feedback line to `replOutput` before it's rendered into the REPL entry: `";; yielded — animation resumed"` (Scheme comment syntax, distinct from evaluation results)
- [x] 2.4 Verify the feedback line appears in the existing `.repl-result` div rendering path without changing the HTML structure

## 3. Manual validation

- [x] 3.1 Reload the sandbox page with a fresh build. Select `starfield.scm`. Click Run. Confirm animation shows 250 stars.
- [x] 3.2 In the REPL, submit `(set! n 50)`. Confirm the animation immediately thins to ~50 stars with no reset or visual hiccup. Confirm no error in the browser devtools console.
- [x] 3.3 In the REPL, submit `(set! n 1000)`. Confirm the animation freezes and the sandbox console shows the "Out of bounds array.get" error message.
- [x] 3.4 Immediately after the crash, in the REPL submit `(+ 1 2)`. Confirm the REPL prints `3`. (Sanity check that the runtime recovered cleanly.)
- [x] 3.5 In the REPL, submit `(set! n 100)`. Confirm no REPL output beyond what ECE's own `set!` emits (ECE returns the new value, so `100` prints — that is not our feedback line). Confirm no error.
- [x] 3.6 In the REPL, submit `(draw)`. Confirm:
  - The REPL entry for `(draw)` contains the feedback line `;; yielded — animation resumed`
  - The canvas animation resumes with ~100 stars
  - The Run/Stop button now shows Stop
  - The animation continues running frame after frame (not just a single frame)
- [x] 3.7 Click Stop. Confirm the animation halts and the button reverts to Run. Confirm `ECE.wasm.get_yield_flag()` is 0 in devtools.
- [x] 3.8 Click Run again. Confirm the program re-runs from scratch with 250 stars (same as a fresh page load).
- [x] 3.9 Test a non-yielding REPL sequence DURING a running animation: `(+ 1 2)`, `(define (test) 42)`, `(test)`. Confirm each behaves as before — values print, no yield feedback line appears (this is the live-edit case — the `!wasRunning` gate prevents false positives).

## 4. Commit

- [x] 4.1 Rebuild sandbox assets if needed (`make sandbox` — only required if something regenerates `sandbox/sandbox.js` from elsewhere; this is a hand-edit so unlikely). Confirmed via Makefile: `make sandbox` builds `ece-runtime.js`, `ece-bootstrap.js`, `ece-compiled.js` — does NOT regenerate `sandbox.js`. No rebuild needed.
- [x] 4.2 Commit with a message naming both fixes: "Sandbox: clear yield state in finishRun + resume yielded computations from evalRepl"
- [x] 4.3 Open PR with the manual test sequence from section 3 as the test plan — https://github.com/anthonyf/ece/pull/145
