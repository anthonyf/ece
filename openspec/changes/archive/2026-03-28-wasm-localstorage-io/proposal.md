## Why

41 tests are CL-only because they use file I/O primitives (IDs 100-103) with no WASM implementation. localStorage provides a natural key-value backing store for file operations in the browser: filename → contents. This also enables save/load for IF games — `save-continuation!` and `load-continuation` work transparently via localStorage.

## What Changes

- File I/O primitives (IDs 100-103) implemented on WASM using localStorage as backing store
- Port primitives (read-char, write-char, peek-char, etc.) get proper WASM buffer-based implementations
- New `$port` WasmGC struct with buffer, position, filename, and direction
- JS glue provides `storage_read`/`storage_write` imports over `localStorage`
- Primitives 100-103 move from `cl` platform to `core` in primitives.def
- All 4 CL-only test files move to common test suite
- `run-cl.scm` becomes empty; `run-all.scm` simplified

## Capabilities

### New Capabilities
- `wasm-port-system`: Buffer-based port implementation in WAT with localStorage backing for file operations
- `wasm-localstorage`: JS glue for localStorage read/write, accessible from WASM via imports

### Modified Capabilities
- `ports`: Port primitives (60-75) gain proper WASM implementations instead of stubs
- `platform-stratified-tests`: All CL-only tests move to common; test suites unified

## Impact

- **wasm/runtime.wat**: ~200 lines — `$port` struct, buffer ops, file I/O primitives
- **wasm/glue.js**: ~20 lines — storage imports, default ports for console I/O
- **primitives.def**: IDs 100-103 change from `cl` to `core`
- **tests/ece/run-common.scm**: gains 4 test files (41 tests)
- **tests/ece/run-cl.scm**: emptied
- **No ECE code changes** — existing file I/O code works unchanged
