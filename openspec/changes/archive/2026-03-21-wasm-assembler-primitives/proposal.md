## Why

The WASM runtime can execute pre-compiled `.ececb` code but cannot compile ECE source at runtime. The self-hosted compiler calls assembler primitives to build instruction vectors and label tables — these are stubs on WASM. This blocks the REPL, `load`, `try-eval`, and the sandbox's runtime compilation.

## What Changes

- Implement ~15 assembler/compiler-support primitives on WASM (IDs 85, 89-97, 125-135)
- These manipulate the existing `$comp-space`, `$instr`, and space registry structures
- `execute-from-pc` (ID 85) enables recursive executor entry for compile-and-go
- `try-eval` (ID 90) wraps evaluate with error handling
- Update sandbox to use ECE's `load` for runtime compilation
- Change space management primitives (125-135) from `cl` to `core` in primitives.def

## Capabilities

### New Capabilities
- `wasm-runtime-compilation`: Self-hosted compiler works on WASM — load, REPL, try-eval all functional

### Modified Capabilities
- `wasm-primitives`: Assembler support primitives implemented (were stubs)
- `primitive-manifest`: IDs 125-135 move from `cl` to `core`

## Impact

- **wasm/runtime.wat**: ~200 lines — primitive implementations for space manipulation
- **wasm/glue.js**: register new primitives in buildGlobalEnv
- **primitives.def**: IDs 125-135 change from `cl` to `core`
- **sandbox/sandbox.js**: evalECE uses ECE's `load` for runtime compilation
- **Existing tests**: must still pass (329 WASM, 496 CL)
