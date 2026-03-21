## Context

ECE's WASM runtime boots in ~100ms, runs 329 tests, and has file I/O via localStorage. The self-hosted compiler, reader, and assembler all work on WASM. This means a browser REPL can compile and run ECE code entirely client-side.

## Goals / Non-Goals

**Goals:**
- Interactive REPL that compiles and runs ECE in the browser
- Code editor with run/stop and canned programs
- Canvas for graphics demos
- Works from `file://` (no server required for testing)
- Anchorable split-pane layout

**Non-Goals:**
- Full IDE features (autocomplete, debugger, etc.)
- Multiple files or project management
- Persistence of user code across sessions (can add later)
- Mobile-optimized layout

## Decisions

### 1. Cooperative yielding via yield primitive

**How it works:**

The `yield` primitive:
1. Captures the current continuation via `call/cc`
2. Stores it in a global slot accessible from JS
3. Sets a yield flag in the executor
4. The executor loop checks the flag and exits, returning to JS

JS resumes on the next animation frame by invoking the stored continuation.

**Stop** = JS drops the continuation reference. The program is simply never resumed. GC cleans up.

**Implementation in WAT:**
```
;; In executor loop, after fetching instruction:
(if (global.get $yield-flag)
  (then
    (global.set $yield-flag (i32.const 0))
    (br $loop-end)))
```

The `yield` primitive (called from ECE code) does:
```scheme
(define (yield)
  (call/cc (lambda (k)
    (%set-yield-continuation! k)
    (%yield!))))  ;; sets flag, executor exits
```

Actually, `yield` needs to be a primitive that both stores the continuation AND signals the executor. A pure ECE function can't signal the executor. So `yield` is a two-part primitive:
- The ECE prelude wraps it with `call/cc` to capture the continuation
- The raw `%yield!` primitive stores the continuation value and sets the flag

### 2. file:// compatible asset loading

Binary assets (runtime.wasm, .ececb files) are embedded as base64 in JS files:

```javascript
// ece-runtime.js
const ECE_WASM_BASE64 = "AGFzbQ...";
const ECE_WASM_BYTES = Uint8Array.from(atob(ECE_WASM_BASE64), c => c.charCodeAt(0));
```

Loaded via `<script src="ece-runtime.js">` which works from `file://`.

A build step (`make sandbox`) generates these JS bundles from the binary files.

### 3. REPL architecture

```
User types in textarea → [Enter or Ctrl+Enter]
     │
     ▼
JS wraps input as: (try-eval (read (open-input-string "...")))
     │
     ▼
Actually, simpler: compile the expression to a fresh space,
execute it, capture the result.
     │
     ▼
Display result in output div (scrolling, styled)
```

Since `try-eval` isn't fully implemented on WASM, the REPL can use a different approach:
- JS passes the input string to ECE's `read` + `mc-compile-and-go`
- This requires calling ECE functions from JS — which we can do by creating a small .ececb "evaluator" that reads from a global string variable and compiles/runs it

Or simpler: a small ECE function `(define (repl-eval str) (eval (read (open-input-string str))))` compiled into a .ececb that the REPL calls.

### 4. Layout system

CSS flexbox with a `flex-direction` property that changes based on anchor position:
- Right anchor: `row` (sandbox left, editor right)
- Left anchor: `row-reverse`
- Bottom anchor: `column` (sandbox top, editor bottom)
- Top anchor: `column-reverse`

A small anchor toggle button [⊞] cycles through positions. The choice persists in localStorage.

Resizable split: a 4px drag handle between the panes. Pure CSS + JS, no library.

### 5. Canvas primitives (IDs 200+)

Minimal set for the first version:

| ID | Name | Args | Description |
|----|------|------|-------------|
| 200 | canvas-clear | 0 | Clear entire canvas |
| 201 | canvas-set-fill-color | 3 | Set fill color (r g b, 0-255) |
| 202 | canvas-fill-rect | 4 | Fill rectangle (x y w h) |
| 203 | canvas-fill-circle | 3 | Fill circle (x y radius) |
| 204 | canvas-draw-text | 3 | Draw text (x y string) |
| 205 | canvas-width | 0 | Get canvas width |
| 206 | canvas-height | 0 | Get canvas height |

All implemented as thin JS imports that call the canvas 2D context.

### 6. Canned programs

Start with one: **Hello World**
```scheme
(display "Hello, World!")
(newline)
```

More can be added later as `.scm` strings in `ece-programs.js`.
