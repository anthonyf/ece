## 1. String ops → ECE

- [x] 1.1 Add `string-downcase`, `string-upcase` to `prelude.scm` (iterate chars, shift case via char->integer/integer->char)
- [x] 1.2 Add `string-trim` to `prelude.scm` (find first/last non-whitespace, substring)
- [x] 1.3 Add `string-contains?` to `prelude.scm` (sliding window substring comparison)
- [x] 1.4 Add `string-split` to `prelude.scm` (walk chars, accumulate segments)
- [x] 1.5 Add `string-join` to `prelude.scm` (fold with separator)
- [x] 1.6 Add `print` to `prelude.scm` (`(define (print x) (display x) (newline))`)
- [x] 1.7 Remove WAT helper functions (`$prim-string-case`, `$prim-string-split`, `$prim-string-trim`, `$prim-string-contains`, `$prim-string-join`) and dispatch cases (36-41, 66) from `runtime.wat`
- [x] 1.8 Rebuild bootstrap, run `make test` and `make test-wasm`

## 2. Browser primitives → FFI

- [x] 2.1 Add canvas functions to `browser-lib.scm`: `canvas-clear`, `canvas-set-fill-color`, `canvas-fill-rect`, `canvas-fill-circle`, `canvas-draw-text`, `canvas-width`, `canvas-height` (with lazy `*canvas-ctx*` init)
- [x] 2.2 Add `sin`, `cos`, `wall-clock-ms` to `browser-lib.scm` via FFI
- [x] 2.3 Remove WAT canvas dispatch (200-206), trig dispatch (152-153), timing dispatch (154) from `runtime.wat`
- [x] 2.4 Remove WASM canvas imports (7), math imports (2), and `wall_clock_ms` import (1) from `runtime.wat`
- [x] 2.5 Remove canvas wiring from `sandbox.js` `init()` (the `ECE.canvas = { ... }` block)
- [x] 2.6 Recompile `browser-lib.ececb`, rebuild sandbox

## 3. Final verification

- [x] 3.1 Run `make test` and `make test-wasm` — all tests pass
- [x] 3.2 Rebuild sandbox (`make sandbox`), verify canvas programs work (Game Loop, Starfield, Analog Clock)
