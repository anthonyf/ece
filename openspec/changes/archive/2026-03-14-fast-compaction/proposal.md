## Why

Image compaction (`compact-for-save`) takes ~8 seconds, with 90% of that time (7.25s) spent in `transitively-retain-blocks`. The function uses `find-block-for-pc` which does a linear scan through all block ranges for every label reference — an O(n * m) pattern where n is the number of label references resolved (~12K labels across ~50K instructions) and m is the number of block ranges (~228). This makes `save-image!` painfully slow.

## What Changes

- Replace the linear-scan `find-block-for-pc` with O(1) hash table lookups in `transitively-retain-blocks`
- Apply the same optimization to `mark-reachable-blocks`, which has the same linear scan pattern (currently 0.15s, minor but same fix)
- Pre-build a PC-to-block-range hash table before entering the hot loops

## Capabilities

### New Capabilities

- `fast-block-lookup`: O(1) PC-to-block-range lookup via pre-built hash table, replacing linear scan in compaction hot paths

### Modified Capabilities

## Impact

- `src/compaction.scm`: Modified functions — `transitively-retain-blocks`, `mark-reachable-blocks`, new helper to build the PC→range hash table. `find-block-for-pc` may be removed or kept for non-hot-path use.
- No changes to image format, serialization, or deserialization
- No changes to the compaction algorithm's correctness — same reachability analysis, same output, just faster lookup
