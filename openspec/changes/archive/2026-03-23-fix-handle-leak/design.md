## Context

The WASM runtime uses a handle table (i32 → GC ref) to pass values across the JS/WASM boundary. Handles are allocated by `$alloc-handle` which increments a counter. `mark_handles` sets a watermark; `reset_handles` resets the counter back to the watermark, recycling all handles above it.

The sandbox calls `mark_handles` after bootstrap, making env/space/primitive handles permanent. But `reset_handles` is never called during the game loop, so handles accumulate until the 8M table overflows.

## Goals / Non-Goals

**Goals:**
- Game loop demos run indefinitely without crashing
- No behavior change — handles are recycled safely

**Non-Goals:**
- True handle recycling (free-list, reference counting) — the watermark approach is sufficient
- Reducing the 8M table size

## Decisions

### 1. Reset at the top of animationLoop

Call `reset_handles()` at the start of each `animationLoop` iteration, before any new handle allocations:

```javascript
animationLoop() {
    if (!Sandbox.running) return;
    ECE.wasm.reset_handles();  // recycle temporary handles from last frame
    ...
}
```

This is safe because:
- The yield continuation is stored in WASM global `$yield-continuation` (a GC ref, not a handle). `get_yield_cont()` allocates a fresh handle from the table — but that happens AFTER the reset.
- All permanent handles (env, primitives, bootstrap spaces) are below the watermark.
- `ECE._hVoid` and `ECE._hNil` are below the watermark (allocated during `buildGlobalEnv` before `mark_handles`).
- Any handle returned from the previous frame's `call_ece_proc` is no longer referenced by JS.

### 2. Also reset in evalECE

The `evalECE` function (for non-game-loop programs) also leaks handles. Add `reset_handles()` before each eval to keep handle usage bounded for REPL and program runs.

### 3. Integration test

Add a test that simulates 100 yield/resume cycles and verifies the handle counter stays bounded (doesn't grow past watermark + some threshold).
