## 1. Primitives manifest

- [x] 1.1 Add FFI primitive entries (IDs 210-221) to `primitives.def`

## 2. WASM runtime

- [x] 2.1 Add `$js-ref` struct type and helper functions (`$make-js-ref`, `$js-ref-idx`, `$is-js-ref`) to `runtime.wat`
- [x] 2.2 Add 5 FFI WASM imports (`ffi.eval`, `ffi.get`, `ffi.set`, `ffi.call`, `ffi.callback`)
- [x] 2.3 Implement primitive dispatch for IDs 210-221 in `$dispatch-op` / `$apply-primitive`
- [x] 2.4 Add `$js-ref` case to `$display-value` (display as `#<js-ref N>`)

## 3. JS bridge

- [x] 3.1 Add JS handle table (allocate, free, get) to `glue.js`
- [x] 3.2 Implement `ffi.eval`, `ffi.get`, `ffi.set`, `ffi.call`, `ffi.callback` as JS import functions
- [x] 3.3 Implement argument marshalling — walk ECE list via exported WASM functions, convert each value to JS
- [x] 3.4 Wire `ffi` imports into the WASM instantiation imports object
- [x] 3.5 Register FFI primitives (210-221) in `buildGlobalEnv`

## 4. ECE library

- [x] 4.1 Create `src/browser-lib.scm` with user-facing wrappers: `js-eval`, `js-call` (rest args), `js-get`, `js-set!`, `js-callback`, type conversions
- [x] 4.2 Add DOM helpers: `get-element-by-id`, `query-selector-all`, `set-text!`, `add-event-listener!`, `class-add!`, `class-remove!`
- [x] 4.3 Compile `browser-lib.scm` to `.ececb` and add to sandbox bootstrap

## 5. Testing

- [x] 5.1 Add WASM test for FFI primitives: `js-eval`, `js-number`/`js-ref->number` round-trip, `js-null?`, `js-ref?`
- [x] 5.2 Test `js-call` with arguments and return value (use `Math.max` or similar)
- [x] 5.3 Test `js-callback` creates a callable JS function
- [x] 5.4 Verify existing canvas programs still work (backward compatibility)
- [x] 5.5 Rebuild sandbox (`make sandbox`) and test browser-lib functions in the REPL
