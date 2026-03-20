# Future Work & Known Limitations

Architectural items to revisit. Not blocking anything currently.

## Per-space instruction vectors grow unboundedly on redefine

**Status:** Documented, deferred.

Each compilation space has an append-only instruction vector. Each `(define (f ...) ...)` appends new instructions. Redefining `f` appends a second copy — the old instructions become unreachable dead code but remain in the vector.

**Impact:** During long REPL sessions with many redefines, the bootstrap space's vector grows. Each function is ~20-50 instructions, so thousands of redefines before it matters. Per-file spaces (from `load`) are scoped and don't accumulate across sessions.

**Why compaction is hard:**
- Compiled procedure values `(compiled-procedure (space . entry-pc) env)` are scattered throughout the environment and captured in closures
- Saved `continue` register values on the stack contain space-qualified addresses
- Captured continuations from `call/cc` contain stack copies with embedded addresses and compiled-procedure values

**Decision:** Accept the growth for now. Not a practical problem during normal development. Per-file spaces from `.ecec` boot keep each module's instructions separate and bounded.

## REPL error recovery after .ecec boot

**Status:** Known issue.

After .ecec boot, error recovery in the REPL can leave stale labels in the bootstrap space. If an expression causes an error during compilation/assembly, the next expression may fail with "Unknown label" because partially-assembled labels pollute the label table.

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

Serialized continuations contain return addresses as `(space . pc)` pairs. If the source code changes and the `.ecec` files are rebuilt, PCs shift and old continuations become invalid. This affects all implementations with serialized continuations — Racket's defunctionalized continuations also break on any code change ("if you change your program in a trivial way, all serialized continuations will be obsolete").

For the browser/localStorage use case (page refresh), this is a non-issue — the same code is running. For cross-version save compatibility (game updates), the recommended approach is to save game state data (the parameter values) separately from the continuation, and use named checkpoints to restart from the closest point.
