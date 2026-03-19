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

## Continuation serialization

**Status:** Removed, needs reimplementation.

The old `save-continuation!` / `load-continuation` primitives depended on the flat-image serializer which was removed with the image machinery. Continuation serialization needs a new implementation that works with the per-space architecture (continuations capture space-qualified addresses).
