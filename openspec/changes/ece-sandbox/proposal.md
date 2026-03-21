## Why

ECE now runs in WebAssembly but has no interactive demo. A browser-based REPL sandbox showcases the language, lets users experiment, and serves as the foundation for shipping IF games as single-page apps. It demonstrates the full stack: WASM runtime, self-hosted compiler, canvas graphics, and continuation-based cooperative yielding.

## What Changes

- New `sandbox/` directory with a complete single-page app
- `yield` primitive using continuations for cooperative multitasking (run/stop/pause)
- Canvas primitives (browser platform IDs 200+) for graphics demos
- Build tooling to embed WASM + bootstrap as base64 in JS files (file:// compatible)
- REPL with multiline input and scrolling output
- Code editor with canned program dropdown and run/stop button
- Split-pane layout anchorable to any screen edge

## Capabilities

### New Capabilities
- `sandbox-app`: Single-page REPL sandbox with editor, REPL, canvas, and console
- `yield-primitive`: Continuation-based cooperative yielding for animation loops and interruptible programs
- `canvas-primitives`: Browser platform primitives for 2D canvas drawing
- `sandbox-build`: Build tooling to package WASM + bootstrap into file://-compatible JS bundles

### Modified Capabilities
- `primitive-manifest`: Add yield (core) and canvas primitives (browser platform IDs 200+)
- `wasm-executor`: Yield flag check in executor loop for cooperative return to JS

## Impact

- **sandbox/**: new directory — index.html, sandbox.js, ece-runtime.js, ece-bootstrap.js, ece-programs.js
- **wasm/runtime.wat**: yield primitive (flag + continuation storage), canvas JS imports, executor yield check
- **wasm/glue.js**: canvas import bridges
- **primitives.def**: yield primitive ID, canvas primitive IDs 200+
- **Makefile**: `make sandbox` target
