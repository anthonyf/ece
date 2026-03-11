## Context

The instruction vector is append-only. Function redefinitions and REPL interactions leave dead code behind. The instruction source vector uses symbolic labels (resolved to PCs at load time), so compaction can work entirely on the source vector — remove dead instructions, rebuild the label table from the compacted vector.

The environment is a list of frames: `((vars...) val1 val2 ...)`. Values include `(compiled-procedure entry-pc env)`, `(primitive name)`, continuations `(continuation stack continue-pc)`, and ordinary data. Macros are compiled procedures in `*compile-time-macros*`.

## Goals / Non-Goals

**Goals:**
- Compact the instruction vector at `save-image!` time, removing unreachable instructions
- Produce smaller image files
- Live system state is untouched — compaction operates on copies
- All existing tests pass unchanged

**Non-Goals:**
- Runtime compaction (would require updating live executor state)
- Changing the instruction format or label resolution mechanism
- Optimizing instruction sequences (just removing dead code)

## Decisions

### Decision 1: Mark reachable instructions via entry-PC collection, not control-flow tracing

Walk all roots to collect reachable entry PCs. Then, for each entry PC, include all instructions from that PC until the next entry PC (or end of vector). This uses the sorted set of ALL entry PCs (reachable and unreachable) as natural procedure boundaries.

**Why not trace control flow?** Control flow tracing (following gotos, branches, labels) is complex and error-prone. But compiled procedures are laid out sequentially by the assembler — each procedure's instructions form a contiguous block from its entry PC to the start of the next procedure. Using entry PCs as boundaries is simple and correct.

**How it works:**
1. Collect ALL entry PCs from the procedure-name table (which records every `define`'d procedure's entry)
2. Walk roots to find REACHABLE entry PCs
3. Sort all entry PCs to determine block boundaries
4. Mark blocks whose entry PC is reachable
5. Copy only marked blocks into the compacted vector

**Alternative considered:** Tracing control flow from each entry point (follow gotos, branches). Rejected — much more complex, and the block-boundary approach is correct because the assembler never interleaves procedures.

### Decision 2: Roots are global env + macro table only

The roots for reachability are:
- All `(compiled-procedure pc env)` values in `*global-env*` frames
- All compiled procedures in `*compile-time-macros*`
- The procedure-name table provides block boundaries but is not itself a root

Continuations stored in the environment contain stacks with raw PCs and compiled procedures. These are walked transitively when walking env values.

**Not roots:** The live executor's pc/continue/stack registers — these are CL local variables and are irrelevant to the saved image (the image captures a fresh starting state).

### Decision 3: Compact into copies, serialize copies, discard

`ece-save-image` builds compacted copies of the instruction source vector, label table, env, and macro table. It serializes the copies. The live state is never modified.

This avoids the executor-state problem entirely: the running system continues with its original instruction vector. The saved image is compact.

### Decision 4: Remap PCs in deep-copied env and macros

After compaction, entry PCs change. Build an `old-pc → new-pc` remapping table. Deep-copy the global env and macro table, walking all values and updating any `(compiled-procedure old-pc env)` to `(compiled-procedure new-pc env)`. Also remap PCs in continuations: the `continue-pc` field and any saved PCs on the stack.

### Decision 5: Labels are symbols in the source vector — rebuild label table from compacted source

The source vector contains symbolic labels (e.g., `ENTRY-42`, `AFTER-LAMBDA-43`). Labels are interspersed with instructions and registered in the label table when assembled. After compacting, rebuild the label table by scanning the new source vector for symbols.

Wait — labels are NOT stored in the source vector. They're consumed during assembly and stored only in the label table. The source vector contains only instructions (lists), not labels.

**Revised approach:** Don't rebuild labels from source. Instead, remap the label table using the same `old-pc → new-pc` mapping. Labels that pointed to dead code are dropped.

## Risks / Trade-offs

**[Risk] Entry PCs don't cover all code** → The procedure-name table only tracks `define`'d procedures. Anonymous lambdas have entry PCs that ARE in compiled-procedure values (in the env) but NOT in the procedure-name table. For block-boundary detection, we need ALL entry PCs (including anonymous ones). Mitigation: collect entry PCs from both the procedure-name table AND by walking all compiled-procedure values in the env/macros.

**[Risk] Shared structure in env** → The global env has circular references (`*print-circle*` handles this). Deep-copying must handle cycles. Mitigation: use a visited-set during deep copy to avoid infinite loops and preserve sharing.

**[Risk] Continuations with stale PCs** → Continuations captured in the live session have PCs into the live vector. After compaction + remap, these PCs point into the compacted vector. If the continuation is invoked after loading the compacted image, the remapped PCs must be correct. Mitigation: the same remap pass handles continuation PCs.

**[Trade-off] Save time increases** → Compaction adds a walk + copy + remap step before serialization. For typical images (~160K instructions), this should be milliseconds. Acceptable tradeoff for smaller images.
