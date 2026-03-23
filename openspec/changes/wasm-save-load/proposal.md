## Why

Save/load is Priority 3 on the ECE roadmap and essential for interactive fiction (save game state, restore at any point). The serializer/deserializer exists in `prelude.scm` and works on the CL runtime, but fails on WASM because compiled procedures, continuations, and primitives are opaque WasmGC structs — the serializer can't detect or decompose them. This blocks the entire save/load feature on the browser target.

## What Changes

- Add type predicate primitives for WASM: `compiled-procedure?`, `continuation?`, `primitive?` (currently internal ops only, not callable from ECE code)
- Add type accessor primitives: `compiled-procedure-entry`, `compiled-procedure-env`, `continuation-stack`, `continuation-conts`, `primitive-id` (extract struct fields as ECE values)
- Add reconstruction primitives: `%make-compiled-procedure`, `%make-continuation` (build WasmGC structs from serialized data)
- Port identity hash tables to WASM: `%eq-hash-table`, `%eq-hash-ref`, `%eq-hash-set!` (needed for shared structure detection)
- Port helper primitives: `%global-env-frame`, `%primitive-name`, `%primitive-id`, `%hash-frame?`
- Update the deserializer in `prelude.scm` to use reconstruction primitives instead of tagged pairs

## Capabilities

### New Capabilities

- `wasm-type-introspection`: ECE code can detect and decompose WasmGC struct types (compiled-procedure, continuation, primitive)
- `wasm-eq-hash`: Identity-based hash tables on WASM for shared structure tracking
- `wasm-value-serialization`: serialize-value/deserialize-value work on both CL and WASM runtimes

### Modified Capabilities

- `value-serialization`: Deserializer updated to use reconstruction primitives (platform-portable)

## Impact

- `wasm/runtime.wat`: ~15 new primitive dispatch cases
- `primitives.def`: ~15 new primitive entries (promote from cl-only to core, or add new)
- `wasm/primitives.json`: Regenerated
- `src/prelude.scm`: Deserializer uses `%make-compiled-procedure` / `%make-continuation` instead of `(list 'compiled-procedure ...)`
- `src/runtime.lisp`: CL implementations of the new reconstruction primitives (trivial — just `list`)
- Tests: round-trip serialization test on WASM
