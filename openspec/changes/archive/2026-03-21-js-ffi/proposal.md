## Why

Adding any new browser capability currently requires changes across four layers: `primitives.def` (new ID), `runtime.wat` (WASM dispatch), `glue.js` (JS import), and `sandbox.js` (usage). This makes every DOM feature, canvas extension, or browser API a multi-file change. A generic FFI lets ECE code call arbitrary JS functions through a small set of primitives, so new browser capabilities become pure ECE — no WASM or JS changes needed.

This also aligns with the Phase 3 roadmap (`browser-lib.scm` for DOM/canvas/audio primitives) and pulls forward the "FFI for user JS libraries" item from the compile-to-host plan.

## What Changes

- Add ~12 FFI primitives to `primitives.def` (IDs 210-221, browser platform)
- Implement a new `$js-ref` value type in `runtime.wat` — an opaque wrapper around a JS handle table index
- Add ~5 WASM imports (`ffi` category) that delegate to JS for object access, method calls, property get/set, and callback wrapping
- Add an FFI bridge in JS (`ffi-bridge.js` or inline in `glue.js`) — a JS handle table mapping i32 indices to JS values, plus the dispatch functions
- Register FFI primitives in `glue.js` `buildGlobalEnv`
- Add `browser-lib.scm` — an ECE library built on FFI primitives providing DOM access, event handling, class manipulation, and canvas helpers

## Capabilities

### New Capabilities
- `js-ffi-primitives`: Core FFI primitives for calling JS from ECE (js-eval, js-get, js-set!, js-call, js-callback, type conversions, js-null?, js-release!)
- `js-ffi-bridge`: JS-side handle table and dispatch functions wired as WASM imports
- `browser-lib`: ECE library providing DOM helpers (get-element-by-id, add-event-listener!, class-add!/remove!, query-selector-all, etc.) built on FFI primitives

### Modified Capabilities

(none — existing canvas primitives remain for backward compatibility)

## Impact

- **primitives.def**: ~12 new entries (IDs 210-221)
- **runtime.wat**: New `$js-ref` value type + ~50 lines primitive dispatch + ~5 new imports
- **glue.js**: FFI bridge (~80 lines) + primitive registration
- **browser-lib.scm**: New file (~100-150 lines), compiled to `browser-lib.ececb`
- **Backward compatibility**: Existing canvas primitives (200-206) remain unchanged. FFI is additive.
