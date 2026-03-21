## 1. WASM Port Struct

- [x] 1.1 Define `$port` WasmGC struct type
- [x] 1.2 Implement `$make-input-port` helper
- [x] 1.3 Implement `$make-output-port` helper

## 2. JS Storage Imports

- [x] 2.1 Add storage read/write JS imports with Map fallback for Node.js
- [x] 2.2 Add WAT import declarations
- [x] 2.3 Linear memory transfer for filenames and content

## 3. File I/O Primitives

- [x] 3.1 open-input-file (prim 100): localStorage → buffer → port
- [x] 3.2 open-output-file (prim 101): empty output port with filename
- [ ] 3.3 with-input-from-file (prim 102): deferred (needs current-port override in display/read-line)
- [ ] 3.4 with-output-to-file (prim 103): deferred
- [x] 3.5 primitives.def: IDs 100-103 → core

## 4. Port Primitives

- [x] 4.1-4.13 All port primitives implemented with buffer-based operations
- [x] display/write with optional port argument (writes to port buffer)
- [x] newline with optional port argument

## 5. Register and Wire

- [x] 5.1 File I/O primitives registered in glue.js
- [x] 5.2 All port primitives wired in dispatch

## 6. Test Suite

- [x] 6.1 test-file-io.scm and test-cross-space.scm moved to run-common.scm
- [x] 6.2 run-cl.scm slimmed (only compilation-units + serialization)
- [x] 6.3 Bootstrap rebuilt

## 7. Validation

- [x] 7.1 CL: 496 passed, 0 failed
- [x] 7.2 WASM: file write/read round-trip works
- [x] 7.3 WASM: existing 329 tests preserved
- [x] 7.4 WASM: file-io tests pass (4/6 — 2 with-*-from-file deferred)
