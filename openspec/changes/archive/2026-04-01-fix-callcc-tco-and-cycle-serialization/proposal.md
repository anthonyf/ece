## Why

Two independent bugs compromise continuation correctness. First, `mc-compile-callcc` always installs a return-label trampoline, even in tail position — this causes `save continue` that is never restored when the receiver tail-calls out, leaking one stack entry per iteration and bloating captured continuations linearly. Second, `deserialize-value` stores `%ser/def` ref-table entries after recursing into the body, so cyclic structures (from `letrec` or recursive `define`) fail to deserialize because the back-reference lookup hits an empty table. Together these make continuation-based patterns (coroutines, generators, state machines, cooperative threading) unreliable.

## What Changes

- Add a tail-position code path to `mc-compile-callcc` in `compiler.scm` that captures the continuation using the caller's `continue` register directly and dispatches to the receiver as a true tail call — no return-label, no save/restore
- Modify `deserialize-value` in `prelude.scm` to pre-allocate mutable placeholders in the ref-table before recursing into `%ser/def` bodies, then patch them after construction — enabling cyclic structure round-trips
- Add tests for both fixes: TCO verification at 1,000,000 iterations, and round-trip tests for `letrec`/recursive-define closures

## Capabilities

### New Capabilities
- `callcc-tail-tco`: Tail-position `call/cc` maintains O(1) stack growth — no register saves leak across tail-recursive iterations
- `cyclic-serialization`: Serialization and deserialization correctly handles cyclic object graphs (closures referencing their own binding frame)

### Modified Capabilities
- `tail-call-optimization`: TCO coverage now includes `call/cc` in tail position
- `value-serialization`: Serialization now handles cyclic structures via pre-allocated placeholders

## Impact

- `src/compiler.scm`: `mc-compile-callcc` gains a second code path for `linkage = 'return`
- `src/prelude.scm`: `deserialize-value` changes deser logic for `%ser/def` to pre-allocate and patch
- `bootstrap/`: Requires `make bootstrap` after compiler change (new .ecec files)
- `tests/ece/`: New test files for tail-position call/cc TCO and cyclic serialization round-trips
