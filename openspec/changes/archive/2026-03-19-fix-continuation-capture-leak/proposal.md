## Why

Serialized continuations are 5KB+ for trivial programs because instruction vectors and source expressions leak into the captured state. A realistic game continuation could be 50-100KB. For the browser/localStorage use case (auto-save after every player choice, survive page refreshes), continuations need to be compact — a few hundred bytes of game state, not tens of KB of compiled instructions.

## What Changes

- **Investigate the leak path**: Trace exactly how instruction vectors and source code enter the continuation's stack and environment chain. The likely paths are: (1) the stack copy from mc-compile-and-go's executor frame containing instruction sequences in registers, (2) the environment chain including frames that reference compilation space vectors, or (3) the serializer following references from compiled procedures into their instruction spaces.
- **Fix the serializer to skip code objects**: Instruction vectors, label tables, and source expressions are "code" — they exist in the running system and don't need to be persisted with the continuation. The serializer should recognize and skip them, serializing only data (values, environments, return addresses).
- **Add compilation-space-aware serialization**: Compiled procedures reference entries like `(PRELUDE . 4523)`. The serializer should NOT follow these into the compilation space's instruction arrays. On deserialization, the entry address is sufficient to reconnect to the current code.
- **Measure and verify**: Add tests that assert continuation size stays below reasonable bounds (e.g., < 1KB for simple programs, proportional to captured data not code).

## Capabilities

### New Capabilities
- `compact-continuation-serialization`: Serialization of continuations that excludes code objects (instruction vectors, label tables, source expressions), producing compact output proportional to captured data, not compiled code size.

### Modified Capabilities
- `value-serialization`: Updated to detect and skip code-like objects (CL vectors containing instructions, compilation-space struct fields) rather than recursively serializing them.

## Impact

- **`src/prelude.scm`**: Update `serialize-value` to recognize and skip compilation space vectors, instruction sequences, and source expressions. Add size-bounded serialization tests.
- **`src/runtime.lisp`**: May need a new primitive to identify "code objects" (e.g., `%code-object?` that checks if a value is an instruction vector or compilation space field).
- **`tests/ece/test-serialization.scm`**: Add size assertion tests for continuations.
