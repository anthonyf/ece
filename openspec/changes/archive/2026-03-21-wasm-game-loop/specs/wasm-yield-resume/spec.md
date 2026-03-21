## ADDED Requirements

### Requirement: Sandbox resumes yield continuations
The sandbox animation loop SHALL invoke the stored yield continuation on each `requestAnimationFrame` callback, enabling frame-paced ECE programs.

#### Scenario: Single yield/resume cycle
- **WHEN** an ECE program calls `(call/cc (lambda (k) (%yield! k)))`
- **THEN** the executor SHALL exit, and the sandbox SHALL resume the continuation on the next animation frame

#### Scenario: Continuous game loop
- **WHEN** an ECE program yields repeatedly in a loop (yield → resume → yield → ...)
- **THEN** the sandbox SHALL schedule a new `requestAnimationFrame` after each resume that yields again

#### Scenario: Program finishes without yielding
- **WHEN** a resumed continuation completes without calling `%yield!` again
- **THEN** the sandbox SHALL call `finishRun()` and return the Run button to its default state
