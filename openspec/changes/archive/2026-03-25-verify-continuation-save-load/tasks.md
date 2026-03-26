## Tasks

### Investigation
- [x] Check what type `loaded-k` actually is after deserialization — it's a compiled-procedure (call/cc wrapper)
- [x] Root cause: env-frames (WasmGC structs) weren't serializable — only global env had a sentinel
- [x] Raw continuations (%raw-call/cc) serialize correctly; call/cc wrappers fail because their env-frames can't serialize
- [x] With env-frame serialization added, call/cc wrapper's env round-trips correctly

### Fix
- [x] Add WASM primitives: `%env-frame?`, `%env-frame-names`, `%env-frame-vals`, `%env-frame-enclosing`, `%make-env-frame` (prims 166-170)
- [x] Add env-frame serialization to prelude: `(%ser/env-frame names vals enclosing)` with `#f` for nil enclosing
- [x] Add env-frame deserialization to prelude
- [x] Raw continuation (`%raw-call/cc`) save/load/invoke works end-to-end
- [x] call/cc continuation save/load works (structure correct) but invoke crashes — the do-winds! wrapper execution pushes to a local stack that isn't part of the serialized continuation. Documented as known limitation.

### Tests
- [x] Add ECE test: env-frame round-trip
- [x] Add ECE test: raw continuation save/load/invoke (bare top-level, not in test thunk)
- [x] Run full test suite: 445 passed, 0 failed (413 ECE + 32 integration); CL all passed
