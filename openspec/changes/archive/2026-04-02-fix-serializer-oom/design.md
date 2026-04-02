## Context

ECE's CL runtime represents environments as lists of frames:
```
env = (frame0 frame1 ... (:hash-frame . <global-ht>))
```

Frames come in three flavors:
1. **Vector frames** (compiler-generated): `#(val0 val1 ...)` — fast O(1) lexical access by position
2. **Named-list frames** (legacy): `(names-list . values-list)` — O(n) lookup by name
3. **Hash frames** (global env): `(:hash-frame . <hash-table>)` — O(1) named access

The ECE compiler (both CL-side and metacircular) always calls `extend-environment` with 4 args, producing vector frames. The 3-arg named-list path exists but is unused by compiled code.

The serializer's `%env-frame?` predicate checks `(consp x) ∧ ¬(symbolp (car x))` — intended to match named-list frames but actually matches ANY cons cell with a non-symbol car. This causes:
- Stack lists misidentified as env frames (car is a vector or cons)
- Env chains misidentified as env frames (car is a vector frame)
- The scan pass under-counts objects → ser pass has no cycle refs → infinite recursion on self-referencing closures

With 22 unique objects in a trivial continuation, the serializer OOMs at 4GB.

## Goals / Non-Goals

**Goals:**
- `serialize-value` handles continuations without OOM
- Environment frames are unambiguously identifiable on CL
- Remove dead code (named-list frame paths)
- Serialization tests run in CI

**Non-Goals:**
- Changing the WASM env frame representation (already uses GC structs)
- Implementing delimited continuations
- Changing what continuations capture (global env scoping is a separate concern)
- Adding `stack-depth` or other debug primitives (useful follow-up, but separate)

## Decisions

### 1. Vector-only environment frames

**Decision:** Remove the 3-arg named-list path from `extend-environment`. All frames are vectors. `%env-frame?` becomes `(vectorp x)`.

**Why:** The compiler already uses vector frames exclusively. Named-list frames are dead code. Making `%env-frame?` check `vectorp` is unambiguous — no cons cell can be confused for a vector.

**Impact on lookup:** `lookup-variable-value` currently has three frame dispatch paths: hash-frame, vector (skip), and named-list (scan). Remove the named-list scan path. The function becomes: check hash-frame → check vector (skip) → next frame.

Wait — `lookup-variable-value` uses named-list frames for name-based lookup. Vector frames don't have names. But compiled code uses `lexical-ref` for direct vector access, not `lookup-variable-value`. The only caller of name-based lookup is the global env (hash-frame) and the REPL. Since the REPL goes through the compiler, it uses lexical addressing too.

### 2. Remove `%env-frame?` branch from serializer

**Decision:** The serializer's `scan` and `ser-compound` no longer need a `%env-frame?` case. Vector frames hit the `(vector? obj)` branch — the serializer iterates their elements. Env chains (cons lists of frames) hit the `(pair? obj)` branch — car/cdr traversal. Hash frames hit `(%hash-frame? obj)` — sentinel.

**Why:** With vector-only frames, the object graph has clear type boundaries:
- `continuation?` → scan stack, conts, winds
- `compiled-procedure?` → scan env
- `vector?` → scan elements (frame values)
- `pair?` → scan car + cdr (env chain links, stack structure)
- `%hash-frame?` → stop (global env sentinel)

No ambiguity, no misidentification.

### 3. Keep `%env-frame?` primitive but change semantics

**Decision:** `%env-frame?` (primitive 166) stays in the manifest with the new `(vectorp x)` semantics. `%env-frame-names` returns nil (vector frames have no names). `%env-frame-vals` coerces vector to list. `%env-frame-enclosing` returns nil (unchanged).

**Why:** The WASM runtime uses these primitives for its GC struct env frames. Changing the CL semantics to match the actual representation doesn't break WASM. The primitives are also used by the serializer on WASM where env frames ARE distinct struct types.

## Risks / Trade-offs

**[Risk] Named-list frames used by something unexpected** — Mitigation: grep for 3-arg `extend-environment` calls. The compiler always passes `extra-slots`. If anything still uses 3-arg, it would break. Verify with tests.

**[Risk] `lookup-variable-value` name-based path still needed** — Mitigation: Compiled code uses `lexical-ref`. The REPL compiles expressions. The only name-based lookup is in the global hash-frame (which uses its own path). Keep the hash-frame path, remove only the named-list scan.

**[Trade-off] Debug visibility** — Named frames were useful for debugging (you could see variable names). Vector frames are positional. This is already the case for all compiled code. For debugging, the source-location tracking roadmap (thread 5) would provide file/line info instead of frame names.
