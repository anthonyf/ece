## Context

Continuations captured by `call/cc` include the entire ECE stack, which may contain references to instruction vectors, source expressions, and compiler metadata. When serialized, these "code objects" bloat the output from a few hundred bytes of actual data to 5KB+ for trivial programs. For the browser use case (auto-save to localStorage after every player choice), compact serialization is critical.

## Goals / Non-Goals

**Goals:**
- Serialized continuations proportional to captured DATA, not CODE
- Sub-1KB for typical game choice points with small game state
- No behavior change for continuation capture/restore — only serialization size affected
- Identify all leak paths and fix them

**Non-Goals:**
- Changing how `call/cc` captures continuations (the capture itself is correct)
- Symbolic PCs or stable label names (separate robustness concern)
- Binary serialization format (separate optimization)

## Decisions

### 1. Investigation-first approach

**Choice:** Start by instrumenting the serializer to measure and categorize what's being serialized. Then fix the specific leak paths found.

**Why:** The leak paths from the explore session are hypothesized but not yet pinpointed with certainty. The serialized output shows instruction-like data, but the exact path (stack vs environment vs transitive reference) needs to be confirmed before fixing.

### 2. Serializer-side filtering (not capture-side)

**Choice:** Fix the serializer to skip code objects, rather than preventing them from entering the continuation at capture time.

**Why:** The continuation capture (`capture-continuation` in runtime.lisp) is a simple `copy-list` of the stack. Changing it would affect ALL continuation behavior. Filtering at serialization time is safer — it only affects what gets written to disk, not how continuations work in memory.

### 3. Skip-and-sentinel approach for code objects

**Choice:** When the serializer encounters a code-like object (instruction vector, compilation space fields, source expression lists), emit a sentinel tag and stop recursing. On deserialization, replace sentinels with reconnection to current state.

```
Instruction vector → (%ser/code-skip)     ;; skip, not needed
Label table        → (%ser/code-skip)     ;; skip, not needed
Source expression  → (%ser/code-skip)     ;; skip, not needed
Compiled proc env  → serialize normally   ;; needed for closures
Global env frame   → (%ser/global-env)    ;; already handled
```

**Why:** Code objects are loaded from `.ecec` files at boot. They don't need to be in the save file. The continuation only needs data (variable bindings, game state) and addresses (PCs to resume at). The code at those PCs is already in memory.

### 4. CL-side helper for code object detection

**Choice:** Add a `%code-vector?` primitive that checks if a CL vector looks like an instruction vector (contains lists starting with instruction opcodes like `assign`, `test`, `goto`, etc.) or if it's the resolved-instructions vector of a compilation space.

**Why:** The serializer (in ECE) can't easily distinguish a data vector `#(1 2 3)` from an instruction vector `#((assign val ...) (test ...))`. A CL primitive can check more efficiently, including identity comparison against known compilation space vectors.

## Risks / Trade-offs

**[Over-filtering]** Skipping too aggressively could lose data needed for restore. Mitigation: only skip objects positively identified as code. Data vectors pass through normally.

**[Under-filtering]** Some code objects might not match the detection heuristic. Mitigation: the investigation phase will enumerate all leak paths before the fix.

**[Deserialization mismatch]** If a saved continuation references code that no longer exists (code updated), the sentinel won't help. Mitigation: this is the existing behavior — code changes already break continuations. The sentinel doesn't make it worse.
