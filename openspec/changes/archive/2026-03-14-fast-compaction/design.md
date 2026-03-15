## Context

Image compaction in `src/compaction.scm` removes dead instruction blocks before serializing an image. The compaction algorithm is correct but has an O(n*m) bottleneck: `find-block-for-pc` linearly scans all block ranges (~228) for every label reference resolved during transitive retention (~12K+ labels across ~50K instructions). Profiling shows `transitively-retain-blocks` takes 7.25s out of 8s total save time.

The compaction code runs as compiled ECE, not native CL. Every unnecessary list traversal is amplified by the register machine dispatch overhead.

## Goals / Non-Goals

**Goals:**
- Reduce `transitively-retain-blocks` from ~7.25s to <0.1s
- Reduce `mark-reachable-blocks` from ~0.15s to <0.01s
- No change to compaction semantics — identical output for identical input

**Non-Goals:**
- Changing the image format or serialization (already fast at 67ms)
- Moving compaction back to CL (conflicts with kernel minimization goal)
- Optimizing cold-boot compilation time
- Adding incremental compaction

## Decisions

### 1. Pre-build a PC→block-range hash table using `%eq-hash-*`

Instead of calling `find-block-for-pc` (linear scan) inside the hot loop, build a hash table mapping every block start PC to its `(start . end)` range before entering `transitively-retain-blocks`. The label table already maps label→PC, and boundaries are known, so this is a one-time O(b) build where b=228.

**Why not binary search?** Binary search over a sorted vector would also work (O(log n) per lookup), but it would require building a vector from the list and implementing binary search in ECE. The `%eq-hash-*` primitives are CL-backed O(1) and already available. Simpler, faster.

**Why not index by every PC in the range?** Only block *start* PCs matter. `find-block-for-pc` finds which range *contains* a target PC by checking `start <= pc < end`. We can't hash every PC in every range (50K entries). Instead, we need a way to map an arbitrary PC to its containing block.

**Approach:** Build a sorted vector of boundary PCs. For a given target PC, use the boundary list to find the largest boundary ≤ target PC (this identifies the block start). Then look up that start in the hash table. Since boundaries are sorted and there are only ~228 of them, even a linear scan of the boundary list for this step is fast. But better: store boundaries in a vector and do a simple descending scan — still O(b) worst case but with tiny constant factor and early exit.

Alternatively, the simplest approach: keep `find-block-for-pc` but pass it the hash table of `start → range` and only scan the boundary starts, not the full range list. Actually, the current approach already scans ranges checking `start <= pc < end` — the issue is it's called thousands of times. The real win is caching results: once we know which block a label's target PC falls in, we never need to look it up again.

**Final approach — PC→block cache:** Add a `pc-to-block` hash table. Before each `find-block-for-pc` call, check the cache. On miss, do the linear scan (only 228 ranges) and cache the result. With ~12K labels but only ~228 distinct blocks, the cache saturates almost immediately.

### 2. Apply the same caching to `mark-reachable-blocks`

`mark-reachable-blocks` has the same `find-block-for-pc` pattern. Pass it the same cache or pre-built lookup.

## Risks / Trade-offs

- **Memory:** An extra hash table with ≤228 entries. Negligible.
- **Correctness:** The lookup returns the same result as the linear scan — same `(start . end)` range for the same PC. No semantic change.
- **Complexity:** Adds one new helper function and a hash table parameter. Net code change is small.
