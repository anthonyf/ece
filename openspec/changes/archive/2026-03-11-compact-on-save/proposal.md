## Why

The instruction vector is append-only — every compilation appends new instructions, and function redefinitions leave dead code behind. Over a session with many redefinitions, the vector grows without bound. For self-hosted image rebuilds (loading all .scm files from an existing image), the vector doubles because old code remains alongside new code. Compacting the instruction vector at `save-image!` time produces minimal images without affecting the running system.

## What Changes

- `save-image!` compacts the instruction vector before serializing: walks all roots (global env, macro table) to find reachable entry PCs, traces instruction flow to mark reachable instructions, builds a compacted vector with remapped PCs, and serializes the compact copy.
- The live system state is untouched — compaction operates on copies.
- Continuations in the environment are handled: their stacks contain saved PCs that need remapping.
- A new helper `compact-instructions` in runtime.lisp performs the mark/compact/remap algorithm.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `image-serialization`: `save-image!` now compacts dead instructions before saving, producing smaller images.

## Impact

- `src/runtime.lisp`: New `compact-instructions` function, `ece-save-image` updated to compact before serializing.
- `bootstrap/ece.image`: Will be smaller after regeneration (no dead code from cold boot).
- No API changes — `save-image!` and `load-image!` signatures unchanged.
- All existing image tests must continue to pass.
