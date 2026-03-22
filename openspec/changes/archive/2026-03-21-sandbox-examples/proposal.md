## Why

The sandbox only has Hello World and a bouncing ball. More examples showcase ECE's strengths (recursion, animation, closures, canvas) and give visitors something compelling to play with. Trig primitives (`sin`/`cos`) are needed to unlock circular and wave-based visuals.

## What Changes

- Add `sin` and `cos` math primitives (IDs 152, 153) — WAT has native `f64.sin`/`f64.cos`
- Add Sierpinski Triangle example — recursive canvas drawing, no animation
- Add Starfield example — animated stars using lists and canvas rectangles
- Add Analog Clock example — trig-based clock hands, animated via yield

## Capabilities

### New Capabilities
- `trig-primitives`: `sin` and `cos` math functions for trigonometry

### Modified Capabilities
_None._

## Impact

- **wasm/runtime.wat**: ~10 lines (sin/cos primitive dispatch)
- **primitives.def**: 2 new entries
- **wasm/glue.js**: register 2 primitives
- **sandbox/ece-programs.js**: 3 new program entries
- Sandbox rebuild required
