## Why

ECE has two `call/cc` mechanisms: `%raw-call/cc` (the SICP register machine primitive) and `call/cc` (an R7RS wrapper that adds `dynamic-wind` support via a lambda that calls `do-winds!`). The wrapper lambda makes continuations non-serializable — invoking a deserialized wrapper crashes because the wrapper's execution pushes to a local stack that isn't part of the serialized continuation.

This forces users to use `%raw-call/cc` (an internal `%`-prefixed primitive) for save/load. User code should never call `%` primitives.

## What Changes

Unify into a single `call/cc` by moving winding logic from a wrapper lambda into the continuation struct + executor:

1. **Add `$winds` field** to the `$continuation` struct — captures `*winding-stack*` at creation time
2. **Modify the executor's continuation invoke handler** — before resuming, compare current `*winding-stack*` with the continuation's captured `$winds`. If different, call `do-winds!` to transition.
3. **Simplify `call/cc`** — becomes just `(%raw-call/cc receiver)`. No wrapper lambda. Raw continuations everywhere.
4. **Remove `%raw-call/cc` from public surface** — `call/cc` is the only API. Continuations are always raw, always serializable, always handle winding correctly.

## Capabilities

### New Capabilities
_None_

### Modified Capabilities
- `callcc-special-form`: `call/cc` produces raw continuations; winding handled at invoke time
- `save-load`: All `call/cc` continuations are now serializable and invokable after deserialization

## Impact

- `wasm/runtime.wat` — `$continuation` struct (add `$winds` field), capture-continuation op (capture `*winding-stack*`), continuation invoke handler (call `do-winds!` if needed)
- `src/prelude.scm` — simplify `call/cc` macro to just `(%raw-call/cc receiver)`
- `src/runtime.lisp` — CL continuation struct needs matching `$winds` field
- `bootstrap/*.ecec` — regenerated
- Serializer/deserializer — update for 3-field continuation (`%ser/continuation stack conts winds`)
- All existing `dynamic-wind` and continuation tests must pass
