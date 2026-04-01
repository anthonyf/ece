## Why

`make test-ece` OOMs because `serialize-value` uses recursive `string-append` which is O(n²) in memory for deep structures. When serialization tests run inside `run-tests` → `try-eval`, compiled procedures capture pathologically deep environment chains, and the quadratic allocation exhausts the heap.

## What Changes

- **Rewrite `serialize-value` in `src/prelude.scm` to use port-based output**: Replace the recursive `string-append` approach with `display` / `write-char` to a string output port. The `ser` helpers become void procedures that write to the port instead of returning intermediate strings. This keeps the serialization logic in ECE (not the CL kernel) and works on both CL and WASM.
- **Add `open-output-string` and `get-output-string` primitives**: Standard R7RS string port operations. ~5 lines each on CL and WASM. Needed by the rewritten serializer and generally useful.

## Capabilities

### New Capabilities

- `open-output-string` / `get-output-string`: standard R7RS string output ports

### Modified Capabilities

- `value-serialization`: O(n) memory for deep environment chain serialization

## Impact

- `primitives.def`: 2 new core entries (`open-output-string`, `get-output-string`)
- `src/runtime.lisp`: ~5 lines for new primitives
- `wasm/runtime.wat`: ~20 lines for WASM implementations
- `src/prelude.scm`: Rewrite `ser` / `ser-compound` / `ser-entry` / `ser-pair` to write to a port instead of returning strings (~80 lines changed, same logic)
- Bootstrap files regenerated
- `make test-ece` target becomes usable (currently always OOMs)
