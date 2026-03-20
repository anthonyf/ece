## Why

ECE is designed as a general-purpose language for interactive fiction and games with graphics. A browser runtime makes ECE programs instantly distributable — no installation, just a URL. The existing architecture (tiny 7-opcode instruction set, .ecec bootstrap files, `primitives.def` manifest with stable numeric IDs, core/cl/browser platform split) was designed with this port in mind. The CL kernel is ~2044 lines — that's the scope of what needs a WASM equivalent.

## What Changes

- New WebAssembly runtime written in hand-crafted, well-commented WAT using WasmGC for memory management
- New binary `.ececb` format for loading compiled ECE programs into the WASM runtime
- New build tool (`ecec-to-binary.scm`) written in ECE to convert `.ecec` → `.ececb`
- New `write-byte` primitive added to support binary output from ECE
- Thin JS glue layer for browser API access (I/O, DOM, canvas)
- All core primitives (IDs 0-99 from `primitives.def`) implemented in WAT
- Browser platform primitives (IDs 200-299, currently reserved) will be defined
- `make bootstrap` extended to produce `.ececb` files alongside `.ecec`

## Capabilities

### New Capabilities
- `wasm-value-representation`: WasmGC type system for ECE values — i31ref fixnums (31-bit), GC structs for pairs/symbols/compiled-procs/continuations/parameters/hash-tables, GC arrays for vectors and UTF-16 strings, singletons for #t/#f/'()/eof/void
- `wasm-executor`: The execute-instructions loop ported to WAT — 7 opcodes (assign, test, branch, goto, save, restore, perform), 6 registers (val, env, proc, argl, continue, stack), compilation space registry, cross-space jumps
- `wasm-environment`: Environment operations in WAT — extend-environment, lookup-variable-value, lexical-ref, lexical-set!, define-variable!, set-variable!
- `wasm-symbols`: Symbol interning in WAT — intern table, symbol->string, string->symbol, symbol equality via ID comparison
- `wasm-primitives`: Core primitive implementations in WAT dispatched by stable numeric ID from primitives.def
- `wasm-binary-format`: Binary `.ececb` format specification and ECE-written converter tool for loading compiled programs into WASM memory
- `wasm-js-glue`: Minimal JavaScript layer for WASM module instantiation, .ececb fetching, and browser API imports (console I/O, DOM, canvas)
- `platform-stratified-tests`: Reorganize ECE test suite into common (all hosts), CL-only, and WASM-only entry points so the same tests validate both runtimes

### Modified Capabilities
- `primitive-manifest`: Add `write-byte` primitive for binary output; begin defining browser platform primitives (200-299)

## Impact

- **New directory**: `wasm/` containing all `.wat` source files and JS glue
- **Build system**: `make bootstrap` extended to also produce `.ececb` files
- **primitives.def**: New `write-byte` entry; browser primitive IDs assigned
- **bootstrap/**: `.ececb` files generated alongside existing `.ecec` files
- **New ECE source**: `ecec-to-binary.scm` build tool
- **Test reorganization**: `tests/ece/run-all.scm` split into `run-common.scm` (platform-independent), `run-cl.scm` (CL-only), `run-wasm.scm` (WASM-only). Existing `run-all.scm` composes common + CL tests — no change to current CL test workflow
- **No changes to existing CL runtime** — this is a new parallel host, not a modification
