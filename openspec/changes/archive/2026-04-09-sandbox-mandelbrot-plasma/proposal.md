## Why

The sandbox currently has 5 example programs (hello-world, bouncing ball, Sierpinski, starfield, analog clock). Adding visually striking fractal and demoscene examples demonstrates ECE's float math, progressive rendering, and real-time animation capabilities. The Mandelbrot set is the universal "real language" benchmark, and plasma is a classic animated effect that contrasts well with the existing discrete-shape demos. Closes #130 and #131.

## What Changes

- Add `sandbox/programs/mandelbrot.scm` — Mandelbrot set fractal renderer with progressive row-by-row rendering and color gradient mapping
- Add `sandbox/programs/plasma.scm` — Animated demoscene plasma effect using overlapping sine waves for smooth color fields
- Register both programs in the sandbox program list so they appear in the UI dropdown

## Capabilities

### New Capabilities
- `mandelbrot-renderer`: Mandelbrot set computation with iteration-based coloring and progressive scanline rendering
- `plasma-effect`: Real-time animated plasma using sine wave color synthesis

### Modified Capabilities

None.

## Impact

- `sandbox/programs/` — two new .scm files
- `sandbox/sandbox.js` or `sandbox/index.html` — add entries to the program list/dropdown
- No changes to the ECE runtime, compiler, or canvas primitives — uses existing APIs only
