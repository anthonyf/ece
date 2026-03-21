## 1. Continuation Resume

- [x] 1.1 Add `call_continuation` WASM export — restores continuation stack/conts, re-enters `$execute`
- [x] 1.2 Wire `animationLoop` in sandbox.js — invoke continuation via `call_continuation` on each rAF tick
- [x] 1.3 Handle resume-then-yield cycle — if program yields again after resume, schedule another rAF
- [x] 1.4 Handle resume-then-finish — if program doesn't yield, call `finishRun()`

## 2. Timing Primitive

- [x] 2.1 Add `performance_now` JS import to WASM (returns i32 ms since page load)
- [x] 2.2 Implement `current-milliseconds` primitive (ID 151) in runtime.wat
- [x] 2.3 Register in primitives.def, glue.js buildGlobalEnv

## 3. Game Loop Example

- [x] 3.1 Add "Game Loop" entry to ece-programs.js — bouncing ball + FPS counter
- [ ] 3.2 Verify canvas-draw-text works with runtime-compiled string expressions

## 4. Validation

- [x] 4.1 Existing WASM tests: 329 pass
- [ ] 4.2 Sandbox: game loop runs at ~60fps with FPS display
- [ ] 4.3 Sandbox: Stop button stops the animation loop
- [ ] 4.4 Rebuild sandbox
