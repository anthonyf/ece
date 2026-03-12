## 1. HAMT foundation functions

- [x] 1.1 Implement `popcount` (count set bits via bit-clearing loop)
- [x] 1.2 Implement `hash-code` with type dispatch: numbers, symbols, strings, pairs, vectors, nil, booleans
- [x] 1.3 Implement `hamt-index` (extract 5-bit index from hash at a given depth) and `hamt-bit` (bitmap with single bit set at index)

## 2. Core HAMT operations

- [x] 2.1 Implement `hamt-lookup` — walk trie using hash bits, handle nodes, leaves, collisions, and missing keys
- [x] 2.2 Implement `hamt-insert` — path-copying insert with structural sharing, handle new leaf, update existing, node expansion, and collision creation
- [x] 2.3 Implement `hamt-remove` — path-copying remove with structural sharing, handle node compaction and collision reduction
- [x] 2.4 Implement `hamt-fold` — recursive walk over all entries in the trie (nodes, leaves, collisions), calling a function with accumulator, key, and value

## 3. Rewire hash-table API to HAMT backend

- [x] 3.1 Rewrite `hash-table` constructor to build a HAMT from alternating key-value pairs, tagged as `(:hash-table count . hamt-root)`
- [x] 3.2 Rewrite `hash-table?` to recognize the new `(:hash-table . ...)` wrapper
- [x] 3.3 Rewrite `hash-ref` to call `hamt-lookup`
- [x] 3.4 Rewrite `hash-has-key?` to call `hamt-lookup` with a sentinel to distinguish missing from nil-valued
- [x] 3.5 Rewrite `hash-set!` to call `hamt-insert` and mutate the wrapper cell's root and count
- [x] 3.6 Rewrite `hash-set` (functional) to call `hamt-insert` and wrap in a new `(:hash-table count . new-root)` cell
- [x] 3.7 Rewrite `hash-remove!` to call `hamt-remove` and mutate the wrapper cell
- [x] 3.8 Rewrite `hash-keys`, `hash-values`, `hash-count` using `hamt-fold` (count also readable from wrapper)

## 4. Serialization and self-evaluation

- [x] 4.1 Update `write-to-string` / printer to serialize HAMT hash tables in the `{k v ...}` literal form (walk trie, emit key-value pairs)
- [x] 4.2 Verify `{k v ...}` reader syntax still produces valid hash tables via the new constructor
- [x] 4.3 Verify image round-trip: `make image` succeeds and hash tables survive save/load

## 5. Verify

- [x] 5.1 Clear FASL cache and `make image` — bootstrap image builds successfully
- [x] 5.2 `make test` — all existing tests pass (688 assertions, 0 failures)
- [x] 5.3 Verify `define-record` works: constructor, accessors, mutators, predicates, copy, functional update
