## Investigation Plan

The crash occurs when:
1. A large .ecec file has many compilation units (~390+)
2. A top-level `(define (f x) ...)` appears late
3. The function is called from a CLOSURE (e.g., test thunk), not from a bare top-level form

Key findings:
- Global env names/vals are in sync (not a mismatch bug)
- Crash is at space=15029 (test compilation space), not the prelude
- Bare calls work; closure invocations crash

### Hypothesis: Closure env vs define-variable! frame mutation

When `(test "name" (lambda () (f 5)))` registers a thunk, the lambda captures the current env. Later, `(define (f x) ...)` runs `define-variable!` which calls `frame-append` — this REPLACES the vals array (creates a new larger array and swaps it into the frame struct). But the thunk's closure captured the env BEFORE the frame was mutated.

Wait — the closure captures a reference to the env-frame struct, and `frame-append` mutates the struct in place (`struct.set $env-frame $vals`). So the closure should see the updated vals array. Unless the closure captured the WRONG frame.

Actually, the closure captures the env CHAIN. Top-level code executes with env = global env. The lambda `(lambda () ...)` at top level captures the global env. Later, `define-variable!` mutates the global env frame. The closure should see the mutation since it holds a reference to the same struct.

### Alternative hypothesis: Space-qualified address issue

The `define` creates a compiled procedure with entry point `(space-id . pc)`. The function body is compiled in the test space. When the thunk invokes `(f 5)`, it looks up `f` via `lookup-variable-value` and gets the compiled procedure. Then it extracts the entry point and jumps to it. If the space-id or PC is wrong, the executor jumps to garbage instructions.

This could happen if the test space's instruction vector is reallocated or if the PC calculation is off for late compilation units.

### Investigation steps

1. Add diagnostic: when the crash occurs, dump the compiled-procedure's space-id and PC for the late-defined function
2. Check if the space/PC points to valid instructions
3. Check if the instruction at the crash PC is sensible
4. Compare the same function defined early vs late — does it get different space/PC values?

## Approach

Depending on findings:
- If space/PC is wrong: fix the compilation unit or instruction vector growth
- If closure env capture is wrong: fix how `define-variable!` interacts with captured envs
- If instruction vector reallocation invalidates references: ensure stable references
