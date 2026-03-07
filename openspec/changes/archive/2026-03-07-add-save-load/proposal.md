## Why

ECE continuations are already serializable (primitives store symbols, not function objects), but there's no way to write them to disk and read them back. Persisting and restoring continuations is useful for any long-running or interruptible program. The roadmap also needs updating since Priorities 1 and 2 are now complete.

## What Changes

- **`save-continuation!`**: Serialize a continuation (or any value) to a file using CL's `write` with `*print-circle*` enabled to handle shared structure.
- **`load-continuation`**: Read a serialized value back from a file using CL's `read` with the ECE readtable.
- **Roadmap update**: Mark Priorities 1 and 2 as complete, mark Priority 3 as current.

## Capabilities

### New Capabilities
- `save-load`: `save-continuation!` and `load-continuation` primitives for serializing values to disk.

### Modified Capabilities
- `readme`: Update roadmap to reflect current progress (Priorities 1–2 done, Priority 3 current).

## Impact

- `src/main.lisp` — New wrapper functions `ece-save-continuation!` and `ece-load-continuation`, new `*wrapper-primitives*` entries, new package exports.
- `tests/main.lisp` — Tests for save/load round-trip with continuations and plain values.
- `openspec/roadmap-if.md` — Update checkboxes for Priorities 1–3.
