## Context

The sandbox `animationLoop` captures the yield continuation handle but never invokes it. The `%yield!` primitive (150) works correctly on the WASM side — it stores the continuation and sets the yield flag, causing `$execute` to exit. The gap is purely in JS: `animationLoop` needs to resume the continuation on each `requestAnimationFrame` tick.

Continuations in ECE are compiled procedures with captured register state. They accept one argument (the return value of `call/cc`). On WASM, a continuation is a `$continuation` struct (type 7 in `dbg_type`).

## Goals / Non-Goals

**Goals:**
- `call/cc` + `%yield!` game loops run at ~60fps in the sandbox
- FPS counter displayed via `canvas-draw-text` using real elapsed time
- A clear, simple game loop example in the editor dropdown

**Non-Goals:**
- Input handling (keyboard/mouse) — separate change
- Audio — separate change
- Optimizing frame timing (vsync, fixed timestep) — keep it simple

## Decisions

### 1. Continuation resume mechanism

Continuations are not compiled procedures — they're `$continuation` structs with saved stack and continuation chain. They can't be called via `call_ece_proc` (which casts to `$compiled-proc`).

On the register machine, continuations are invoked by restoring the saved stack and jumping. The compiled code for `(k value)` in ECE generates:
```
(test (op continuation?) (reg proc))
(branch (label apply-continuation))
...
apply-continuation:
(assign stack (op continuation-stack) (reg proc))
(assign val (reg argl))  ;; the argument to k
(goto (reg continue))
```

**Choice:** Add a `call_continuation` WASM export that restores the continuation's stack state and re-enters `$execute`. This mirrors how the register machine invokes continuations:
1. Set `$val` to the resume value (void)
2. Restore the continuation's saved stack
3. Extract the saved `continue` register from the continuation's conts
4. Re-enter `$execute` from the saved return point

Actually simpler: the continuation's stack contains all saved registers. The continuation's conts field is the saved continue register. We can set these up via globals (like `$execute-argl`/`$execute-proc`) and call `$execute` with the right space/pc extracted from the continue address.

### 2. Time primitive

**Choice:** Add `current-milliseconds` as primitive ID 87... no, 87 is `set-macro!`. Next available core slot is 83... no, that's `sleep`. Looking at gaps: ID 151 is available (after `%yield!` at 150).

Actually, reuse the pattern from sleep: add a JS import `performance_now` that returns `Date.now()` (or `performance.now()` for sub-ms precision). The WASM primitive calls the import and returns a fixnum.

**Choice:** Use `performance.now()` for precision, but return as integer milliseconds (fixnum). Primitive ID 151, name `current-milliseconds`.

### 3. canvas-draw-text string handling

`canvas-draw-text` (204) currently calls `$display-value` to write the string to linear memory, then calls the JS `draw_text` import. The JS side reads back from linear memory. This works but the string in linear memory might be overwritten between the display call and the draw call if anything else writes to memory.

**Choice:** Keep the existing mechanism — it works for single-threaded execution. Verify it handles runtime-compiled strings correctly (the string is a `$string` GC ref, `$display-value` copies it to linear memory).

## Risks / Trade-offs

- **Continuation resume correctness**: The continuation captures the full register machine state. Restoring it incorrectly could corrupt execution. Mitigation: test with simple yield/resume cycles before adding the game loop.
- **Fixnum overflow for timestamps**: `Date.now()` returns ~1.7 trillion ms. ECE fixnums are 30-bit signed (~500M max). We need to use a relative timestamp (ms since page load) via `performance.now()`, which stays small. Mitigation: use `performance.now()` not `Date.now()`.
