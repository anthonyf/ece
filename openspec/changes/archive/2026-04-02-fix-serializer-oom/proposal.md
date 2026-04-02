## Why

`serialize-value` OOMs (4GB) when serializing even a trivial continuation captured via `eval-string`. Investigation traced the root cause to `%env-frame?` on CL: it matches any cons cell whose car is not a symbol, misidentifying stack lists, env chains, and other pairs as environment frames. This causes the scan pass (pass 1) to under-count object visits, so the ser pass (pass 2) has no cycle-detection refs for self-referencing compiled procedures — resulting in infinite recursion and heap exhaustion.

The deeper issue: CL's environment frames are `(names-list . values-list)` cons pairs, indistinguishable from regular pairs. But the ECE compiler already uses vector frames for all compiled code (via 4-arg `extend-environment`). The named-list frame path is dead code for compiled ECE. We should remove the ambiguity by making `%env-frame?` check `(vectorp x)`, matching the actual runtime representation.

## What Changes

- **Remove named-list env frames from `%env-frame?`** — change from `(consp x) ∧ ¬(symbolp (car x))` to `(vectorp x)`. This matches the actual frames produced by the compiler (vector frames from `extend-environment` with `extra-slots`).
- **Remove the `%env-frame?` branch from the serializer** — vector frames are already handled by the `(vector? obj)` branch. The env LIST (cons chain of vector frames ending at hash-frame) is handled by the `(pair? obj)` branch. The `%env-frame?` serializer branch was only needed for the old named-list frames that no longer exist.
- **Remove the 3-arg (named-list) path from `extend-environment`** — it's unused by compiled code. Keep only the 4-arg vector frame path.
- **Update `lookup-variable-value` and `set-variable-value!`** — remove the `scan-frame` named-list path, keep only vector and hash-frame dispatch.
- **Re-enable serialization tests in CI** — the `test-ece` target currently excludes `test-serialization.scm` due to this OOM. Once fixed, include it.

## Capabilities

### Modified Capabilities
- `value-serialization`: Serializer correctly handles continuations without OOM — `%env-frame?` no longer misidentifies pairs as env frames
- `instruction-executor`: `extend-environment` only produces vector frames; `lookup-variable-value` simplified

## Impact

- `src/runtime.lisp` — `extend-environment`, `lookup-variable-value`, `set-variable-value!`, `ece-%env-frame-p`, `ece-%env-frame-names`, `ece-%env-frame-vals`
- `src/prelude.scm` — serializer `scan` and `ser-compound` functions: remove `%env-frame?` branch
- `Makefile` — re-enable serialization tests in `test-ece`
- `tests/ece/test-serialization.scm` — verify round-trip continuation works without OOM
