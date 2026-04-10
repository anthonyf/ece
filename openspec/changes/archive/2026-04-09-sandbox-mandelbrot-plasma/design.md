## Context

The sandbox has 5 demo programs and a manifest-based registration system (`sandbox/programs/manifest.sexp`). All drawing uses 7 canvas primitives from `browser-lib.scm`: clear, set-fill-color, fill-rect, fill-circle, draw-text, width, height. The Sierpinski example already demonstrates pixel-level plotting via 1x1 `canvas-fill-rect` calls with progressive `yield`-based rendering.

## Goals / Non-Goals

**Goals:**
- Add two visually striking demos that showcase ECE's float math and rendering
- Follow the same patterns as existing examples (standalone .scm, yield-based animation)
- Run at acceptable frame rates in the WASM sandbox

**Non-Goals:**
- No new canvas primitives or runtime changes
- No zoom/pan interactivity (no keyboard input currently)
- No performance optimization of the canvas pipeline itself

## Decisions

### Mandelbrot: progressive scanline rendering
Render row-by-row (one or a few rows per frame via `yield`), sweeping top to bottom. This matches the Sierpinski batch approach and gives satisfying visual feedback. Each pixel is a 1x1 `canvas-fill-rect` call.

**Alternative considered:** Render all at once, then display. Rejected — blocks for too long and loses the progressive rendering visual appeal.

### Mandelbrot: iteration-to-color mapping
Use a simple RGB gradient computed from the iteration count with modular arithmetic — no lookup table needed. Points inside the set render black. This keeps the code short and avoids needing arrays for palette storage.

### Plasma: block-based rendering for performance
Render in 4x4 blocks rather than individual pixels. A 400x300 canvas at 1x1 would need 120K fill-rect calls per frame — too slow for 60fps animation. At 4x4 blocks: ~1,875 calls per frame, which is comparable to the starfield's 250 draws per frame.

**Alternative considered:** 2x2 blocks (finer detail but 4x more draw calls). Can tune later if performance allows.

### Program registration
Add entries to `sandbox/programs/manifest.sexp` — the existing manifest-based system. No code changes needed.

## Risks / Trade-offs

- **Performance of plasma at higher resolution** — If 4x4 blocks look too chunky, we can try 2x2, but frame rate may drop. Mitigation: start with 4x4, tune down if smooth enough.
- **Float precision in WASM** — Mandelbrot needs decent float precision for detail. The WASM runtime handles floats as tagged byte-list doubles, so precision should be fine. Existing examples (starfield, clock) confirm float math works.
- **Mandelbrot render time** — At ~120K pixels with up to 100 iterations each, full render may take several seconds of wall time. This is acceptable since progressive rendering makes it watchable.
