## Why

The `%yield!` primitive stores a continuation and sets the yield flag, but the sandbox's `animationLoop` never resumes the continuation — it's a stub with a TODO. This means any ECE program using `call/cc` + `%yield!` for frame-paced animation runs exactly one frame and stops. Wiring up continuation resume unlocks game loops, animations, and interactive canvas programs on WASM.

## What Changes

- Wire yield continuation resume in `sandbox.js` `animationLoop` — invoke the stored continuation via `call_ece_proc` on each `requestAnimationFrame` callback
- Add `current-milliseconds` primitive (new core ID) returning `Date.now()` as a fixnum — needed for FPS calculation
- Add a "Game Loop" example program to `ece-programs.js` — bouncing ball with FPS counter, demonstrating `call/cc` + `%yield!` frame pacing
- Verify `canvas-draw-text` works end-to-end with runtime-compiled strings

## Capabilities

### New Capabilities
- `wasm-yield-resume`: Yield continuation resume in the sandbox animation loop, enabling frame-paced ECE programs
- `timing-primitive`: `current-milliseconds` primitive for time measurement

### Modified Capabilities
- `yield-primitive`: `%yield!` now has a working resume path on WASM (was store-only)

## Impact

- **sandbox/sandbox.js**: `animationLoop` wired to invoke continuation (~10 lines)
- **wasm/runtime.wat**: `current-milliseconds` primitive implementation
- **wasm/glue.js**: JS import for time, register new primitive
- **primitives.def**: New primitive ID for `current-milliseconds`
- **sandbox/ece-programs.js**: Game loop example source (~30 lines)
- Sandbox rebuild required
