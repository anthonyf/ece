## ADDED Requirements

### Requirement: yield primitive for cooperative multitasking
A `yield` primitive SHALL capture the current continuation, store it for JS access, and cause the executor to return to JS. JS can resume execution by invoking the stored continuation.

#### Scenario: Animation loop
- **WHEN** an ECE program calls `(yield)` inside a loop
- **THEN** the executor SHALL return to JS, which can resume on the next animation frame

#### Scenario: Stop via continuation drop
- **WHEN** JS does not resume the stored continuation
- **THEN** the program SHALL be effectively stopped with no cleanup needed

### Requirement: Executor yield flag
The WASM executor loop SHALL check a yield flag after each instruction fetch. When set, the executor exits and returns the current val register to JS.

#### Scenario: Yield flag checked
- **WHEN** the yield primitive sets the flag
- **THEN** the executor SHALL exit on the next loop iteration
