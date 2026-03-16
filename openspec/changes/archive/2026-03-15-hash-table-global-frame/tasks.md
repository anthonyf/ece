## 1. Hash-table Frame Type

- [x] 1.1 Add `hash-frame-p` predicate: check for `(:hash-frame . <hash-table>)` cons cell
- [x] 1.2 Update `lookup-variable-value` to dispatch on hash-table frames (gethash before list scan)
- [x] 1.3 Update `set-variable-value!` to dispatch on hash-table frames
- [x] 1.4 Update `define-variable!` to dispatch on hash-table frames
- [x] 1.5 Update `*global-env*` initialization to build a hash-table frame from primitives

## 2. ECE-side Primitives

- [x] 2.1 Implement CL functions: `ece-%hash-frame-p`, `ece-%hash-frame-entries`, `ece-%make-hash-frame`, `ece-%hash-frame-set!`
- [x] 2.2 Register primitives in `*wrapper-primitives*` (not operation tables — these are wrapper primitives like `%eq-hash-*`)
- [x] 2.3 Update `compaction.scm`: `collect-entry-pcs-from-env` to handle hash-table frames via `%hash-frame?` / `%hash-frame-entries`
- [x] 2.4 Update `compaction.scm`: `deep-copy-and-remap` to deep-copy hash-table frames via `%make-hash-frame` / `%hash-frame-set!`

## 3. Binary Serialization

- [x] 3.1 Add `+data-hash-frame+` type tag constant
- [x] 3.2 Update `bin-serialize-data` to handle hash-table frames: emit tag, entry count, then key-value pairs
- [x] 3.3 Update `bin-collect-symbols` to walk hash-table frame entries
- [x] 3.4 Update `bin-deserialize-data-stream` to reconstruct hash-table frames from the new tag

## 4. Bootstrap & Integration

- [x] 4.1 Regenerate `bootstrap/ece.image` with hash-table global frame via `make image`
- [x] 4.2 Run full test suite (`make test`) — all tests must pass
- [x] 4.3 Profile and compare: test suite time with hash-table frame vs previous
      Results: main=555s avg, hash-table=95s avg → 5.8x speedup
