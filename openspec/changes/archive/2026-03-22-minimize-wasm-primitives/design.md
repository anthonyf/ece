## Context

The WASM runtime has three categories of primitives that can leave:

1. **Browser primitives** (canvas, trig, timing) — each is a thin WASM import that delegates to JS. The FFI can do the same delegation from ECE, eliminating the WASM middleman.
2. **String ops** — complex algorithms (split, trim, contains, join, case conversion) implemented in WAT. These can be written in ECE using the remaining string primitives (`string-length`, `string-ref`, `substring`, `string-append`, `char-whitespace?`).
3. **print** — trivially `(display x) (newline)`.

## Goals / Non-Goals

**Goals:**
- Remove ~250 lines of WAT and ~10 WASM imports
- Implement equivalent functionality in ECE (~110 lines)
- Maintain identical API — all existing code continues to work
- All tests pass after migration

**Non-Goals:**
- Optimizing FFI call overhead (future codegen work)
- Removing the canvas/math/timing JS stubs entirely (they're harmless no-ops in glue.js and needed for backward compat with non-FFI paths)
- Moving any primitives that operate on WasmGC types (pairs, vectors, symbols, etc.)

## Decisions

### 1. Canvas functions get a `*canvas-ctx*` js-ref

`browser-lib.scm` will hold a `*canvas-ctx*` variable initialized lazily. Canvas functions use it:
```scheme
(define *canvas-ctx* #f)
(define (canvas-ctx)
  (when (not *canvas-ctx*)
    (set! *canvas-ctx*
      (js-call (js-call (js-eval "document") "getElementById"
                (js-string "sandbox-canvas"))
               "getContext" (js-string "2d"))))
  *canvas-ctx*)
```

**Alternative**: Pass the context as an argument to every canvas call — rejected because it changes the API.

### 2. String ops go in prelude.scm (not browser-lib.scm)

String ops are platform-independent — they use only core primitives. They belong in the prelude so they're available on both CL and WASM. On CL, the existing CL implementations continue to be used (the prelude definitions only matter for the WASM runtime where the WAT implementations are being removed).

**Actually**: Since prelude.scm runs on both CL and WASM, and the CL runtime already has these primitives implemented natively, the ECE prelude definitions would shadow the CL primitives. This is fine — the ECE implementations use only core primitives that work on both platforms.

### 3. Remove WAT dispatch but keep primitive IDs

The primitive IDs (36-41, 66, 152-154, 200-206) stay in `primitives.def` as documentation. The WAT dispatch for these IDs is removed — if called as primitives, they'll hit the "unknown primitive" fallback (returns void). But since the ECE definitions shadow them in the environment, the primitive dispatch is never reached.

### 4. Remove WASM imports for canvas, math, timing

The `canvas`, `math`, and `timing` import categories are removed from `runtime.wat`. The `glue.js` stubs remain as no-ops (they're harmless and needed for the `wasm/test.js` import object). The `sandbox.js` canvas wiring in `init()` is removed since `browser-lib.scm` now handles canvas context setup.

### 5. Order: string ops first, then browser primitives

String ops are simpler (pure ECE, no FFI) and affect both runtimes. Do them first, test, then do browser primitives which only affect WASM.

## Risks / Trade-offs

- **String op performance**: ECE string ops will be slower than the WAT implementations (interpretation overhead). For typical IF/game use, string operations are infrequent. If profiling shows a bottleneck, individual ops can be moved back to WAT.
- **Canvas FFI overhead**: Each canvas call now goes through FFI dispatch instead of a direct WASM import. For 60fps games with hundreds of draw calls per frame, this could matter. → Mitigation: Starfield works at 60fps with the interpreter; the FFI adds constant overhead per call, not per-pixel.
- **`*canvas-ctx*` initialization**: The lazy init assumes a canvas element with id `sandbox-canvas` exists. If browser-lib is loaded in a non-sandbox context, the init will fail. → Mitigation: Guard with `platform-has?` or document the requirement.
