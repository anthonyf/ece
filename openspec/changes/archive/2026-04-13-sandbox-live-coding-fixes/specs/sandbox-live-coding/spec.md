## ADDED Requirements

### Requirement: Sandbox clears yield state on runtime errors
When a game loop running in the sandbox raises an error during a frame and the error is caught by `animationLoop`'s error handler, the sandbox SHALL clean up the WASM runtime's yielded-computation state so that subsequent REPL evaluations that yield are not poisoned by the dead frame's continuation.

Specifically, `Sandbox.finishRun()` SHALL call `ECE.wasm.clear_yield_cont()` and `ECE.wasm.set_yield_flag(0)` in addition to its existing UI-reset behaviour. This is the same cleanup that `Sandbox.stop()` performs.

#### Scenario: Runtime error leaves no stale yield state
- **WHEN** a sandbox game loop raises an uncaught error during a frame (e.g. out-of-bounds vector access)
- **AND** the error is caught by `animationLoop`'s try/catch block
- **AND** `finishRun()` executes
- **THEN** `ECE.wasm.get_yield_flag()` SHALL return 0
- **AND** `Sandbox.hasYieldCont()` SHALL return false
- **AND** `Sandbox.running` SHALL be false

#### Scenario: REPL evaluation after a crash behaves normally
- **WHEN** a game loop crashes and `finishRun` has cleaned up yield state
- **AND** the user enters a new expression in the REPL
- **THEN** the REPL SHALL evaluate the expression using the same code path as before the crash
- **AND** no stale yield state from the crashed frame SHALL affect the new evaluation

### Requirement: REPL evaluation resumes yielded computations
When a REPL expression yields a continuation via `call/cc` + `%yield!` (e.g. by calling a procedure that contains a `(yield)`) while the sandbox is NOT currently pumping an animation loop, the sandbox SHALL automatically start pumping that continuation via the animation loop rather than leaving it orphaned.

Specifically, `Sandbox.evalRepl()` SHALL capture `Sandbox.running` before invoking `call_ece_proc` on `eval-string-last`. After the call returns, it SHALL check `ECE.wasm.get_yield_flag()` or `Sandbox.hasYieldCont()` ONLY if `Sandbox.running` was false before the eval — because if the sandbox was already pumping a loop, any existing yield state belongs to that loop's in-flight continuation, not to the REPL eval. If the prior-running flag is false and the yield state indicates a pending yielded computation, `evalRepl()` SHALL:

1. Set `Sandbox.running` to true
2. Update the Run/Stop button text and CSS class to the "Stop" state
3. Call `Sandbox.animationLoop()` to begin scheduling frames
4. Append a feedback line (a Scheme comment beginning with `;;`) to the REPL output entry indicating that the evaluation yielded and the animation loop was resumed

#### Scenario: REPL call to a game loop starts the animation loop
- **WHEN** the user types a REPL expression that calls a procedure which yields (e.g. `(draw)` where `draw` contains `(yield)`)
- **AND** the expression is evaluated successfully through its first frame
- **AND** the evaluation returns with `$yield-flag = 1`
- **THEN** `Sandbox.running` SHALL become true
- **AND** the Run/Stop button SHALL show the "Stop" state
- **AND** `Sandbox.animationLoop()` SHALL have been called
- **AND** the REPL output entry for that input SHALL contain a Scheme-comment feedback line indicating yielded resumption

#### Scenario: Non-yielding REPL evaluation is unaffected
- **WHEN** the user types a REPL expression that does not yield (e.g. `(+ 1 2)`, `(set! x 10)`, `(define (f) 42)`)
- **AND** the expression is evaluated successfully
- **THEN** `Sandbox.running` SHALL remain at its prior value (typically false)
- **AND** the Run/Stop button state SHALL NOT change
- **AND** `Sandbox.animationLoop()` SHALL NOT be called as a result of this evaluation
- **AND** the REPL output SHALL follow the existing `write_val` rules (print values, silent for void, error for unbound)
- **AND** NO yielded-resumption feedback line SHALL be appended to the REPL output

#### Scenario: Live-edit during a running animation does not re-trigger the yield branch
- **WHEN** a game loop is already running (`Sandbox.running` is true and `animationLoop` is pumping frames via `requestAnimationFrame`)
- **AND** the user evaluates any REPL expression — yielding or not — while the loop is live
- **THEN** `evalRepl()` SHALL NOT treat any stored yield-continuation as "this eval yielded", because the stored continuation belongs to the in-flight animation loop, not to the REPL eval
- **AND** NO yielded-resumption feedback line SHALL be appended to the REPL output
- **AND** `Sandbox.animationLoop()` SHALL NOT be called a second time from `evalRepl()`
- **AND** the running animation SHALL continue uninterrupted on the next frame, observing any mutations from the REPL eval (e.g. `(set! n 50)`)

#### Scenario: Crash-then-resume cycle completes without page reload
- **WHEN** the user runs `starfield.scm` via the Run button and the animation begins
- **AND** the user evaluates `(set! n 1000)` in the REPL, triggering an out-of-bounds error on the next frame
- **AND** `finishRun` runs and clears yield state
- **AND** the user evaluates `(set! n 100)` in the REPL
- **AND** the user evaluates `(draw)` in the REPL
- **THEN** the animation SHALL resume with 100 stars
- **AND** no page reload SHALL be required
- **AND** top-level state (the `star-angle` / `star-dist` / `star-speed` vectors and their existing contents) SHALL be preserved from before the crash
- **AND** the REPL output for `(draw)` SHALL show the yielded-resumption feedback line

### Requirement: Sandbox preserves non-live-coding paths
The changes required for live coding SHALL NOT alter the sandbox's existing non-live-coding workflows.

#### Scenario: Run button still re-runs a program cleanly
- **WHEN** the user selects a program and clicks Run
- **THEN** the sandbox SHALL evaluate the program source via the existing `evalECE` code path
- **AND** if the program yields, the sandbox SHALL start the animation loop via the existing `run()` post-eval yield check
- **AND** the behaviour SHALL be identical to before this change

#### Scenario: Stop button still halts a running animation
- **WHEN** an animation is running and the user clicks Stop
- **THEN** `stop()` SHALL be called
- **AND** `Sandbox.running` SHALL become false
- **AND** `ECE.wasm.clear_yield_cont()` and `ECE.wasm.set_yield_flag(0)` SHALL be called
- **AND** the Run/Stop button SHALL revert to the Run state
- **AND** subsequent Run clicks SHALL start the program fresh

#### Scenario: Pre-compiled program path is unaffected
- **WHEN** the user runs a program that has a pre-compiled `.ecec` entry in `ECE_COMPILED`
- **AND** the source has not been edited
- **THEN** `evalECE` SHALL take the pre-compiled branch as before
- **AND** the behaviour SHALL be identical to before this change
