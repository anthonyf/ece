## Why

ECE's hash tables are alist-based with O(n) for all operations. This is fine for small tables (define-record with 3-5 fields) but breaks down at scale — compaction with ~500+ entries required falling back to CL-backed `%eq-hash-*` primitives. A Hash Array Mapped Trie (HAMT) provides O(~1) operations in pure ECE using the existing vector and bitwise primitives, keeping the language self-hosted while solving the performance problem.

## What Changes

- Replace the alist-based hash table internals with a HAMT (Hash Array Mapped Trie) using compact bitmapped nodes backed by ECE vectors
- Add a `hash-code` function that computes 32-bit hashes for all ECE value types (numbers, symbols, strings, pairs, vectors, nil)
- Add a `popcount` helper for bitmap indexing
- Keep the existing `hash-table`, `hash-ref`, `hash-set!`, `hash-set`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-remove!` API — no breaking changes to user code
- Small tables (below a threshold) may remain as alists for low overhead; above the threshold, the HAMT representation is used
- **BREAKING**: The internal representation changes from `(:hash-table . alist)` to a HAMT structure. Code that directly manipulates the alist internals (rather than using the API) will break.

## Capabilities

### New Capabilities
- `hamt-internals`: Core HAMT data structure — node representation, hash function, popcount, lookup, insert, remove, and iteration over a compact bitmapped trie

### Modified Capabilities
- `hash-table-ops`: The public API functions (`hash-ref`, `hash-set!`, etc.) are reimplemented on top of the HAMT backend instead of alist scans
- `hash-table-literals`: Constructor `(hash-table 'k1 v1 ...)` now builds a HAMT internally
- `define-record`: Records are built on hash tables — no API changes but internal representation changes

## Impact

- `src/prelude.scm` — hash table section rewritten; new HAMT functions added before the existing hash-table API
- `src/compaction.scm` — may be able to replace `%eq-hash-*` usage with native HAMT tables (stretch goal; `%eq-hash-*` can remain as a CL fast path for now)
- Image serialization — `%write-image` / image loader must handle the new HAMT node structure (vectors + bitmaps are already serializable types)
- `define-record` — no code changes needed; it uses the hash-table API which retains its interface
- All existing tests should pass without modification (API is unchanged)
