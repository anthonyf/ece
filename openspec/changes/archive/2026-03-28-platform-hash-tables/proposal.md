## Why

The HAMT-based hash table implementation in the prelude uses 32-bit FNV-1a hash constants (2166136261, 4294967295) that overflow WasmGC's i31ref 30-bit fixnum range, causing all 23 hash table and record test failures on the WASM host. Rather than patching the hash function or adding boxed integers, the cleaner fix is to make hash tables platform primitives — the same pattern already used for cons/car/cdr, vectors, and strings. This also improves performance: a single native primitive call replaces dozens of ECE function calls per lookup.

## What Changes

- Hash table operations (`hash-table`, `hash-ref`, `hash-set!`, `hash-remove!`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-table?`) become core platform primitives
- Prelude hash table wrapper functions replaced with thin primitive calls
- HAMT implementation moved to `lib/hamt.scm` as an optional library (persistent/immutable hash maps)
- New `tests/ece/test-hamt.scm` for HAMT-specific tests
- CL host wires new primitive IDs to existing `%eq-hash-*` functions
- WASM host wires new primitive IDs to existing `$hash-*-impl` functions
- `define-record` and all user code unchanged (uses the API, not HAMT internals)
- Fixes all 23 remaining WASM test failures

## Capabilities

### New Capabilities
- `platform-hash-primitives`: Core primitive IDs for hash table operations, implemented natively on each host
- `hamt-library`: HAMT implementation preserved as a loadable library with its own tests

### Modified Capabilities
- `hash-table-ops`: Hash table operations switch from HAMT-backed to platform-native backing
- `hash-table-literals`: `(hash-table key val ...)` constructor becomes a primitive instead of an ECE macro expanding to HAMT calls

## Impact

- **primitives.def**: New core primitive IDs for hash table operations
- **src/prelude.scm**: ~200 lines of HAMT code removed, replaced with thin primitive wrappers
- **src/runtime.lisp**: New CL primitive implementations wiring to CL hash tables
- **wasm/runtime.wat**: Wire existing `$hash-*-impl` functions to new primitive IDs
- **lib/hamt.scm**: New file — HAMT code moved from prelude
- **tests/ece/test-hamt.scm**: New file — HAMT-specific tests
- **bootstrap/*.ecec and *.ececb**: Rebuilt (prelude changes)
- **No user-visible API changes** — all existing hash table code works unchanged
