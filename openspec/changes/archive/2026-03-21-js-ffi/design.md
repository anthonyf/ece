## Context

ECE's WASM runtime currently exposes browser features through dedicated primitives (canvas-clear, canvas-fill-rect, etc.), each requiring a numeric ID in `primitives.def`, a WASM import, a JS implementation, and WAT dispatch code. This is O(n) work per feature. The FFI provides a generic bridge so new features are O(1) — just write ECE code.

The WASM runtime already has a handle table (i32 → WasmGC eqref) for ECE values. JS objects can't be stored as WasmGC refs, so we need a second handle table on the JS side.

## Goals / Non-Goals

**Goals:**
- Generic mechanism for ECE code to call any JS function, access any JS property, and register ECE callbacks as JS event handlers
- Small primitive surface (~12 primitives) that enables a rich ECE-side library
- `browser-lib.scm` demonstrating DOM access, event handling, and canvas operations via FFI
- Backward compatible — existing canvas primitives (200-206) remain

**Non-Goals:**
- Rewriting sandbox.js in ECE (future work that builds on this)
- Automatic GC of JS handles (pragmatic manual/optional release for now)
- JS Promise/async integration
- TypedArray or ArrayBuffer access

## Decisions

### 1. Two handle spaces

ECE values live in the WASM handle table (i32 → WasmGC eqref). JS values live in a JS-side array (i32 → any JS value). ECE represents JS refs as a new `$js-ref` value type that wraps the JS-side index.

```
ECE Handle Table (WASM)     JS Handle Table (JS)
┌────┬──────────┐           ┌────┬──────────────┐
│ 0  │ fixnum   │           │ 0  │ <reserved>   │
│ 1  │ pair     │           │ 1  │ document     │
│ 2  │ js-ref(1)│──────────▶│ 2  │ <canvas el>  │
│ ...│          │           │ ...│              │
└────┴──────────┘           └────┴──────────────┘
```

**Alternative**: Store JS values as externref in WASM — rejected because WasmGC and externref don't mix well in the current instruction dispatch, and the JS table approach is simpler.

### 2. `js-call` binds `this` automatically

`(js-call obj "method" arg1 arg2 ...)` calls `obj.method(arg1, arg2, ...)` with `obj` as `this`. This is the natural semantics for DOM APIs. For bare function calls, pass `js-null` as the object.

**Alternative**: Separate `js-method-call` and `js-call` — rejected as unnecessary complexity.

### 3. Rest args for variadic calls

ECE's compiler supports `&rest` parameters. `js-call` is defined as:
```scheme
(define (js-call obj method . args)
  (%js-call obj method args))
```
The raw primitive `%js-call` receives the args as an ECE list. The JS bridge walks the list to build the JS argument array.

### 4. Callbacks via `js-callback`

`(js-callback ece-proc)` wraps an ECE compiled procedure as a JS function. The JS wrapper calls `call_ece_proc` when invoked. This works because callbacks fire asynchronously (after the current `$execute` returns via yield or completion).

The wrapped JS function is stored in the JS handle table and returned as a `$js-ref`.

### 5. Primitive IDs 210-221

Following the existing convention (browser primitives at 200+), FFI primitives start at 210:

| ID  | Name | Args | Description |
|-----|------|------|-------------|
| 210 | %js-eval | (string) | Evaluate JS string, return js-ref |
| 211 | %js-get | (js-ref string) | Get property, return js-ref |
| 212 | %js-set! | (js-ref string value) | Set property |
| 213 | %js-call | (js-ref string args-list) | Call method with args list |
| 214 | %js-callback | (proc) | Wrap ECE proc as JS function |
| 215 | %js-ref->number | (js-ref) | Extract number from JS value |
| 216 | %js-ref->string | (js-ref) | Extract string from JS value |
| 217 | %js-number | (number) | Wrap ECE number as JS value |
| 218 | %js-string | (string) | Wrap ECE string as JS value |
| 219 | %js-null? | (js-ref) | Check for null/undefined |
| 220 | %js-release! | (js-ref) | Free a JS handle |
| 221 | %js-ref? | (value) | Type predicate for js-ref values |

Raw primitives are prefixed `%js-`. `browser-lib.scm` provides the user-facing wrappers (e.g., `js-call` with rest args).

### 6. WASM `$js-ref` value type

A new struct type wrapping the JS handle index:
```wat
(type $js-ref (struct (field $idx i32)))
```

The primitive dispatch extracts `$idx` and passes it to JS imports. JS imports return an i32 index that gets wrapped in a new `$js-ref`.

### 7. JS bridge: 5 WASM imports

```wat
(import "ffi" "eval"     (func $js-ffi-eval (param i32) (result i32)))
(import "ffi" "get"      (func $js-ffi-get (param i32 i32) (result i32)))
(import "ffi" "set"      (func $js-ffi-set (param i32 i32 i32)))
(import "ffi" "call"     (func $js-ffi-call (param i32 i32 i32 i32) (result i32)))
(import "ffi" "callback" (func $js-ffi-callback (param i32) (result i32)))
```

Parameters are JS handle indices (i32) and string pointers (via linear memory). The `call` import takes object index, method string pointer, method string length, and an args-array handle. The JS side unpacks the args from the WASM handle table.

### 8. Value marshalling in `%js-call`

The args list `(arg1 arg2 ...)` is an ECE list. The WASM primitive dispatch walks the list, converting each element:
- `$js-ref` → use the JS index directly
- fixnum/float → convert to JS number via a helper import
- string → copy to linear memory, pass to JS
- boolean → convert to JS true/false
- nil → JS null

The conversion happens in WASM, not JS, to minimize import calls. A single `ffi.call` import receives a "packed args" array in linear memory.

**Simpler alternative**: Pass the ECE list handle to JS and let JS walk it via exported WASM functions (h_car, h_cdr, dbg_type). This avoids complex WASM-side marshalling.

Decision: **Use the simpler JS-side approach** — pass the args list handle to JS, let JS walk it. This keeps the WASM changes minimal and leverages existing exports.

## Risks / Trade-offs

- **Performance**: FFI calls go through JS dispatch, which is slower than dedicated WASM primitives. → Mitigation: Keep dedicated canvas primitives for hot inner loops; FFI is for setup/event handling code.
- **Handle leaks**: JS handles aren't automatically freed. → Mitigation: `js-release!` for explicit cleanup; most sandbox refs are long-lived. Can add weak-ref support later.
- **Callback re-entrancy**: If a synchronous DOM operation triggers a callback during `$execute`, re-entrant `call_ece_proc` would corrupt state. → Mitigation: DOM callbacks are async (fire from the event loop after yield/completion). Document this constraint.
- **Linear memory contention**: String marshalling shares the linear memory region at offset 0 with `display` and canvas `draw-text`. → Mitigation: Single-threaded execution means no concurrent access; each operation completes before the next.
