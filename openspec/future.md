# Future Work & Known Limitations

Architectural items to revisit. Not blocking anything currently.

## Instruction vector grows unboundedly on redefine

**Status:** Documented, deferred.

`*global-instruction-vector*` is append-only (SICP 5.5 design). Each `(define (f ...) ...)` appends new instructions. Redefining `f` appends a second copy — the old instructions become unreachable dead code but remain in the vector.

**Impact:** During long REPL sessions with many redefines, the vector grows. Each function is ~20-50 instructions, so thousands of redefines before it matters. Image save/load does NOT compact — `*global-instruction-source*` is also append-only.

**Where PCs live (why compaction is hard):**
- `*global-label-table*` — label symbols to integer PCs (easy to update)
- `*procedure-name-table*` — integer PCs to name symbols (easy to update)
- Compiled procedure values `(compiled-procedure <entry-pc> <env>)` — scattered throughout the environment and captured in closures (hard to find all)
- Saved `continue` register values on the stack — integers (hard to find)
- Captured continuations from `call/cc` — contain stack copies with embedded PCs and compiled-procedure values (very hard to update, may be serialized to disk)

**Key insight:** Instructions store labels as symbols, resolved at runtime via `*global-label-table*`. The hard part is not the instructions themselves but the *escaped integer PCs* in compiled-procedure values, stack frames, and continuations.

**Approaches explored:**

| Approach | Pros | Cons |
|----------|------|------|
| Full compaction (GC-style) | Recovers all space | Must rewrite every escaped PC; breaks saved continuations |
| In-place rewrite (overwrite old slot) | No PC rewriting if new code fits | Larger redefines still append; need range tracking |
| Compact on save only | No runtime complexity | Saved images still clean; breaks serialized continuations |
| Symbolic entry PCs in compiled-procedure | Redefine just updates label table | Changes closure semantics (old closures see new code) |

**Decision:** Accept the growth for now. Not a practical problem during normal development. Revisit if long-running sessions or large-scale code loading makes it noticeable.
