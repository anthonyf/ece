## 1. Entry PC collection

- [x] 1.1 Add `collect-all-entry-pcs` — walk global env, macro table, and procedure-name table to collect every entry PC (including anonymous lambdas)
- [x] 1.2 Add `collect-reachable-entry-pcs` — walk only global env and macro table (the roots) to collect reachable entry PCs

## 2. Mark and compact

- [x] 2.1 Add `mark-reachable-blocks` — given all entry PCs (sorted) and the reachable set, return list of (start . end) ranges for live blocks
- [x] 2.2 Add `compact-instruction-vector` — copy live blocks into a new vector, build old-pc → new-pc remapping table

## 3. Remap

- [x] 3.1 Add `remap-label-table` — produce new label table with remapped PCs, dropping labels that pointed to dead code
- [x] 3.2 Add `remap-procedure-name-table` — produce new procedure-name table with remapped PCs
- [x] 3.3 Add `deep-copy-and-remap-env` — deep-copy an environment, remapping PCs in compiled procedures and continuations (handle cycles via visited set)
- [x] 3.4 Add `deep-copy-and-remap-macros` — deep-copy macro table, remapping PCs in compiled transformer procedures

## 4. Integration

- [x] 4.1 Add top-level `compact-for-save` that orchestrates: collect PCs → mark → compact → remap → return compacted copies of all state
- [x] 4.2 Update `ece-save-image` to call `compact-for-save` and serialize the compacted copies instead of live state

## 5. Verify

- [x] 5.1 Regenerate bootstrap image (`make image`) and verify it loads correctly
- [x] 5.2 Run `make test` — all existing tests pass
- [x] 5.3 Add test: define a function, redefine it, save image, load image — function works and instruction vector is smaller
- [x] 5.4 Add test: anonymous lambda survives compaction round-trip
