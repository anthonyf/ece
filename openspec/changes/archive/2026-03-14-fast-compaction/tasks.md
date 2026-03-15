## 1. Cached Block Lookup

- [x] 1.1 Add `find-block-for-pc-cached` function to `src/compaction.scm` that takes `target-pc`, `all-ranges`, and a `cache` hash table — checks cache first, falls back to linear scan and caches the result
- [x] 1.2 Update `mark-reachable-blocks` to create a cache and pass it to `find-block-for-pc-cached` instead of calling `find-block-for-pc`
- [x] 1.3 Update `transitively-retain-blocks` to create a cache and pass it to `find-block-for-pc-cached` instead of calling `find-block-for-pc`

## 2. Verification

- [x] 2.1 Run `make image` and verify the output image is identical (diff against previous)
- [x] 2.2 Run `make test` and `make test-ece` to confirm no regressions
- [x] 2.3 Time `save-image!` — `transitively-retain-blocks` dropped from 7.25s to 1.67s, total save from 8.0s to 2.5s (3.2x speedup)
