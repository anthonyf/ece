## Why

The WASM executor produces different behavior than the CL executor for identical compiled instructions. Specifically, complex nested save/restore sequences (from multi-arg function calls with recursive arguments) crash on WASM but work correctly on CL. The compiler output is correct — the same `.ecec` instructions pass CL serialization tests but crash on WASM when serializing proper lists.

The workaround (rewriting prelude code to use simpler patterns) masks the bug. Any future prelude code using `(f A B (recursive-call ...))` with 3+ args will hit the same crash. The executor needs to be fixed.

## What Changes

- Add an instrumented save/restore trace to the WASM executor (compile-time flag, zero production cost)
- Add matching CL executor trace for comparison
- Run the failing case (serialize-value on a proper list) on both, diff the save/restore logs
- Identify and fix the exact executor bug
- Add a regression test for the specific failing pattern

## Capabilities

### New Capabilities

- `executor-trace`: Compile-time-optional trace of save/restore operations for debugging executor bugs

### Modified Capabilities

## Impact

- `wasm/runtime.wat`: Instrumented save/restore with JS callback (behind compile flag)
- `src/runtime.lisp`: Matching CL trace output
- `wasm/test.js` or standalone script: Comparison harness
- Once fixed: revert the ser-pair workaround in prelude.scm back to the original cleaner pattern
