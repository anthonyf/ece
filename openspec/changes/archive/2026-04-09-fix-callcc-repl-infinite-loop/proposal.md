## Why

Continuations captured by `call/cc` in the REPL cause infinite loops when invoked. Each `mc-compile-and-go` call appends instructions to the shared global compilation space with linkage `'next` (fall-through). Labels like `after-call` are placed at the past-end PC. When the next REPL expression is compiled, its instructions start at that same PC, so the old label no longer marks the boundary. Invoking the captured continuation replays the original code and returns to the old label — which now falls through into the next compilation unit's code, re-invoking the continuation in an infinite loop.

## What Changes

- Add a `halt` instruction to the register machine instruction set that forces the executor to exit immediately (equivalent to reaching past-end PC)
- `mc-compile-and-go` appends a `(halt)` instruction after each compiled expression, creating an execution barrier between compilation units
- The WASM executor (`execute-instructions` in WAT) gets the same `halt` instruction support

## Capabilities

### New Capabilities
- `halt-instruction`: A register machine `halt` instruction that terminates the executor, used as a barrier between REPL compilation units

### Modified Capabilities
- `compile-and-go`: Append a `halt` instruction after each compiled expression to prevent fall-through between compilation units
- `instruction-executor`: Handle the new `halt` instruction by exiting the execution loop

## Impact

- `src/runtime.lisp` — instruction dispatch in `execute-instructions`
- `src/compiler.scm` — `mc-compile-and-go` instruction list construction
- `src/wat/runtime.wat` — WASM executor instruction dispatch (if applicable)
- No API or user-facing changes beyond fixing the bug
- No breaking changes — `halt` is only emitted by the compiler internally
