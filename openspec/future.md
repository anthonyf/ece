# Future Work & Known Limitations

Architectural items to revisit. Not blocking anything currently.

> *Compilation spaces retired in per-procedure-code-objects (2026-04): the compilation unit is now the `code-object`, `.ecec` is a code-object archive (version 2), and the executor dispatches on code-objects via struct field access. Entries below that still reference "spaces" are preserved as historical context and rewritten in terms of code-objects below each old "Status" block.*

## Per-procedure instructions reclaim on redefine

**Status:** Resolved by per-procedure-code-objects (2026-04).

Previously: each compilation space had an append-only instruction vector; redefining `(define (f ...) ...)` appended a second copy and the old instructions became unreachable dead code but stayed in the vector.

After per-procedure-code-objects each `(define ...)` produces a fresh `code-object` whose instructions live on the code-object struct itself. Redefining rebinds the name to a new closure pointing at a new code-object; the old code-object becomes unreferenced and is GC'd naturally (modulo any captured closures or saved continuations that still point at it — those keep it alive, which is correct). There is no longer a shared per-file instruction vector to grow.

## REPL error recovery after .ecec boot

**Status:** Known issue.

After .ecec boot, error recovery in the REPL can leave stale labels in the bootstrap code-object. If an expression causes an error during compilation/assembly, the next expression may fail with "Unknown label" because partially-assembled labels pollute the label table of the REPL's resident code-object.

**Workaround:** Single expressions work fine. The issue only manifests when an error occurs mid-compilation and the REPL tries to compile the next expression.

## Continuation serialization and global state

**Status:** Reimplemented. Known limitation with global state documented.

`save-continuation!` / `load-continuation` are reimplemented in ECE (~170 lines in prelude.scm). The serializer handles all ECE types, shared structure, and uses `%ser/` tagged s-expressions. Parameters are stored in the ECE environment and serialize automatically.

**Global state limitation:** The global environment is replaced by a sentinel during serialization — global `define` bindings are NOT captured. This is the same limitation as Racket's stateless servlets ("the store is not serialized"). The recommended pattern is to keep mutable state in lexical scope (inside a function), where `call/cc` captures it naturally. See the README's "Lexical State Pattern" section.

**Alternatives considered and rejected:**
- **Serialize all user globals (boot-time diff):** Would capture everything added to `*global-env*` after boot. Simple but coarse — saves irrelevant globals and doesn't distinguish game state from helper function definitions.
- **User-declared manifest (`define-saveable`):** User lists which globals to save. Explicit but fragile — forgetting a variable causes silent data loss.
- **Automatic liveness analysis:** Walk the instruction stream from the continuation's return address to find referenced globals. Feasible for direct references but intractable for transitive references through function calls. GraalVM Espresso does this but has the advantage of JIT-level liveness data.
- **Lexical state pattern (chosen):** Keep mutable state inside a function scope. `call/cc` captures it automatically. External pure functions receive values as arguments. No language changes needed, correct by construction. Matches how Racket's stateless servlets work in practice.

## Return address stability across code changes

**Status:** Known limitation, not unique to ECE.

Serialized continuations contain return addresses as `(code-obj . pc)` pairs (previously `(space . pc)`). If the source code changes and the `.ecec` files are rebuilt, PCs shift and old continuations become invalid. This affects all implementations with serialized continuations — Racket's defunctionalized continuations also break on any code change ("if you change your program in a trivial way, all serialized continuations will be obsolete").

For the browser/localStorage use case (page refresh), this is a non-issue — the same code is running. For cross-version save compatibility (game updates), the recommended approach is to save game state data (the parameter values) separately from the continuation, and use named checkpoints to restart from the closest point.
