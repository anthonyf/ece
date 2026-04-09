## Why

The direct let/let* compiler (commit eec191d) is implemented but dormant — the old bootstrap.ecec still compiles let/let* via macro expansion. Two bugs surfaced during the bootstrap attempt that must be fixed before the new compiler can self-host: (1) `mc-compile-let` corrupts the stack when a `let` has 2+ bindings whose inits are function calls, and (2) non-tail let/let* env restoration via `enclosing-environment` breaks the env chain in deeply nested code. Until bootstrap is regenerated, the performance improvement (eliminating N procedure objects per let*) is not realized.

## What Changes

- **Fix `mc-compile-let` env chain corruption** — The `preserving '(env)` in the eval-and-save loop interleaves `save env`/`save val`/`restore env` incorrectly: `restore env` pops `val` instead of `env` when 2+ bindings have function-call inits. Root cause identified; fix approach validated (use `mc-construct-arglist`).
- **Fix non-tail let/let* env restoration** — When `enclosing-environment` is active (operations.def entry 27 present), deeply nested non-tail let/let* produces "NIL is not of type SIMPLE-VECTOR". The env chain terminates prematurely. Requires debugging the interaction between `extend-environment`, `enclosing-environment`, and the global hash-frame env terminator.
- **Add `enclosing-environment` to boot-env.scm asm symbols** — WASM runtime needs the new operation registered in the asm symbol table (slot 44). Update `(%init-asm-syms 45)`.
- **Two-pass `make bootstrap`** — Regenerate bootstrap.ecec so the new compiler is the active compiler at boot time.
- **Verify FPS improvement** — Sandbox game-loop program should show improved FPS with let* no longer creating lambda overhead.

## Capabilities

### New Capabilities
_(none — this is a bug-fix and bootstrap activation change)_

### Modified Capabilities
- `compiled-file-boot`: Boot process must handle the `enclosing-environment` operation (op-id 27) in compiled instruction streams from the new compiler.

## Impact

- **`src/compiler.scm`** — Bug fixes to `mc-compile-let` (stack ordering) and potentially `mc-compile-let*` (env chain).
- **`src/boot-env.scm`** — Add asm symbol slot 44 for `enclosing-environment`, bump count to 45.
- **`bootstrap/bootstrap.ecec`** — Regenerated with new compiler active.
- **Sandbox programs** — Performance verification target.
