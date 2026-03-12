## Context

ECE hash tables are alist-based: `(:hash-table (k . v) ...)`. All operations (lookup, insert, delete) are O(n). This was acceptable for small tables but became a bottleneck during image compaction with hundreds of entries, requiring a parallel `%eq-hash-*` system backed by CL. ECE now has vectors (`make-vector`, `vector-ref`, `vector-set!`) and full bitwise operations (`bitwise-and`, `bitwise-or`, `bitwise-xor`, `arithmetic-shift`), which are the building blocks for a Hash Array Mapped Trie (HAMT).

## Goals / Non-Goals

**Goals:**
- Replace alist internals with a HAMT for O(~1) lookup, insert, and delete
- Keep the existing public API (`hash-ref`, `hash-set!`, `hash-set`, etc.) unchanged
- Support all existing key types (symbols, numbers, strings, pairs) via a generic `hash-code` function
- Maintain both mutable (`hash-set!`) and functional (`hash-set`) variants
- Ensure image serialization round-trips correctly (HAMT nodes are vectors and pairs — already serializable)

**Non-Goals:**
- Replacing `%eq-hash-*` primitives in compaction (they can remain as a CL fast path)
- Implementing resizable/rehashable tables (HAMT doesn't need rehashing)
- Changing the `{k v ...}` reader syntax or `define-record` macro (they use the API, not internals)

## Decisions

### 1. HAMT with compact bitmapped nodes

**Decision:** Use a compact HAMT where each internal node is `(bitmap . entries-vector)`. The bitmap is a 32-bit integer; bit `i` set means logical slot `i` is occupied. The entries-vector has length `(popcount bitmap)`, containing only occupied entries. Each entry is either a leaf `(key . val)` or a child HAMT node.

**Why not a simple 32-wide vector at each node?** Wastes memory for sparse tables. A table with 5 entries would allocate 32-slot vectors at each level. The compact representation only allocates slots for entries that exist.

**Why not a tree (red/black, treap)?** Trees require a total ordering on keys. ECE keys can be symbols, numbers, strings, pairs — defining a universal `compare` is awkward and fragile. HAMT only needs a hash function plus `equal?` for collisions, matching the existing API semantics exactly.

**Why not CL-backed?** The project direction is moving primitives into pure ECE. CL-backed hash tables would reverse that. HAMT uses existing ECE primitives (vectors, bitwise ops) and stays self-hosted.

### 2. Hash function: FNV-1a style, type-dispatched

**Decision:** Implement `hash-code` that returns a 32-bit integer for any ECE value:
- **Numbers:** Multiply by a large prime, mask to 32 bits
- **Symbols:** Hash the symbol name string
- **Strings:** FNV-1a character-by-character (XOR each char code, multiply by FNV prime)
- **Pairs:** XOR of `(hash-code car)` and `(hash-code cdr)` rotated
- **Vectors:** Fold hash-code over elements
- **Nil:** Constant 0
- **Booleans:** `t` → constant (nonzero)

FNV-1a is simple (2 operations per byte), has good distribution, and is easy to implement in ECE with `bitwise-xor` and `bitwise-and`.

### 3. 5-bit branching factor (32-way)

**Decision:** Each HAMT level consumes 5 bits of the 32-bit hash, giving 32 possible children per node and a maximum depth of 7 (with 2 bits unused at the deepest level, but collisions are handled separately).

At depth 7, if two keys still collide (same hash), store them in a collision node: a tagged list `(:collision (k1 . v1) (k2 . v2) ...)` scanned linearly. True hash collisions are extremely rare.

### 4. Representation and tagging

**Decision:** Use tagged structures to distinguish node types:

- **Empty HAMT:** `(:hamt)` — the empty hash table sentinel
- **HAMT node:** `(:hamt-node bitmap entries-vector)` — internal trie node
- **Collision node:** `(:hamt-collision entries-alist)` — for full hash collisions
- **Hash table wrapper:** `(:hash-table . hamt-root)` — top-level tag for `hash-table?` predicate

The `:hash-table` wrapper tag is preserved so `hash-table?` continues to work. The internal structure changes from an alist to a HAMT root node.

### 5. Mutable `hash-set!` via path copying with root mutation

**Decision:** `hash-set!` walks down the trie, creates new vectors along the modified path (structural sharing for unchanged subtrees), and mutates the root cell's CDR to point to the new root. This preserves object identity (the cons cell returned by `hash-table` is the same cell) while the internal trie structure is replaced.

`hash-set` (functional) does the same path copy but wraps the new root in a fresh `(:hash-table . new-root)` cons cell, leaving the original unchanged.

### 6. `popcount` via bit-clearing loop

**Decision:** Implement `popcount` as:
```
(define (popcount n)
  (define (loop n count)
    (if (= n 0) count
        (loop (bitwise-and n (- n 1)) (+ count 1))))
  (loop n 0))
```
This clears the lowest set bit each iteration, running in O(bits set) — at most 32 iterations. Simple, correct, no dependency on integer width tricks.

### 7. Iteration via recursive tree walk

**Decision:** `hash-keys`, `hash-values`, and `hash-count` walk the trie recursively, collecting entries. `hash-count` can be stored in the wrapper for O(1) access: `(:hash-table count . hamt-root)`.

## Risks / Trade-offs

**[Constant overhead for small tables]** → For tables with 1-5 entries, HAMT has higher constant overhead (hashing, bitmap ops, vector allocation) than a simple alist scan. Mitigation: benchmark after implementation. If needed, keep alist representation below a threshold (e.g., 8 entries) and promote to HAMT on growth. Start without this optimization; add only if benchmarks justify it.

**[Hash collision quality]** → Poor hash distribution could cause many collision nodes, degrading to O(n). Mitigation: FNV-1a has well-studied distribution properties. Test with diverse key types.

**[Image serialization]** → HAMT nodes are vectors and tagged lists — both already handled by the image serializer. The `deep-copy-and-remap` in compaction.scm walks pairs and doesn't enter vectors, which is correct since HAMT vectors contain no PCs. Risk is low but needs verification.

**[`hash-set!` identity semantics]** → The current `hash-set!` mutates alist cells directly. The new approach mutates the wrapper cons cell's CDR. Code that holds a reference to the wrapper cell (the normal case) works correctly. Code that held a reference to internal alist structure (undocumented, fragile) would break. This is an acceptable breakage.

**[Memory usage]** → Compact HAMT nodes use vectors sized to popcount. A node with 3 children allocates a 3-element vector. This is more memory-efficient than 32-wide sparse vectors, but more than alists for very small tables. Acceptable tradeoff for O(1) operations.
