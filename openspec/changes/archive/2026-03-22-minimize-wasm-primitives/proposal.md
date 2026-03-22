## Why

The WASM runtime (`runtime.wat`) contains ~250 lines of primitive implementations that can now be expressed as ECE code — either as pure ECE (string ops) or via the JS FFI (canvas, trig, timing). Moving these out of the WASM kernel advances the "minimize the CL kernel" goal: smaller kernel = easier WASM rewrite, and more logic lives in portable .scm files editable without recompiling WASM.

The JS FFI (merged in PR #31) makes this possible for browser primitives. The string primitives were always expressible in ECE but were implemented in WAT for historical reasons.

## What Changes

- **Canvas primitives (200-206)**: 7 primitives move from WAT dispatch + JS imports to ECE functions in `browser-lib.scm` using FFI. Remove 7 WASM canvas imports and ~48 lines of WAT dispatch + the `$string-to-memory` call for draw-text.
- **Trig (sin, cos)**: 2 primitives move to ECE via `(js-call (js-eval "Math") "sin" ...)`. Remove 2 WASM math imports and ~8 lines WAT.
- **Timing (wall-clock-ms)**: 1 primitive moves to ECE via FFI. Remove 1 WASM timing import and ~3 lines WAT.
- **String ops (string-split, string-trim, string-contains?, string-join, string-downcase, string-upcase)**: 6 primitives move to pure ECE in `prelude.scm` using `string-length`, `string-ref`, `substring`, `string-append`, `char-whitespace?`. Remove ~156 lines of WAT helper functions + ~30 lines dispatch.
- **print**: 1 primitive becomes `(define (print x) (display x) (newline))` in prelude. Remove ~6 lines WAT.
- **Backward compatibility**: Same function names, same behavior. Calling code unchanged.

## Capabilities

### New Capabilities

(none — existing APIs reimplemented in a different layer)

### Modified Capabilities

(none — no spec-level behavior changes, pure implementation migration)

## Impact

- **runtime.wat**: Remove ~10 WASM imports, ~250 lines of WAT (helper functions + dispatch). Reduces from ~4800 to ~4550 lines.
- **prelude.scm**: Add ~60 lines (string ops + print)
- **browser-lib.scm**: Add ~50 lines (canvas + trig + timing via FFI)
- **glue.js**: Remove canvas/math/timing stub objects (~25 lines). Keep `ffi` imports.
- **sandbox.js**: Remove canvas wiring in `init()` (~20 lines) — browser-lib handles it now.
- **Bootstrap**: Must rebuild after prelude changes.
- **Risk**: Low — mechanical migration with test suite validation.
