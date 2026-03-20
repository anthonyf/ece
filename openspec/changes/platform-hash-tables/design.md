## Context

ECE hash tables are currently implemented as HAMTs (Hash Array Mapped Tries) in pure ECE (`prelude.scm`, ~200 lines). The HAMT uses FNV-1a hashing with 32-bit constants that overflow WasmGC's i31ref range. Meanwhile, both hosts already have native hash table infrastructure: CL has `%eq-hash-*` primitives (IDs 116-124), and WASM has `$hash-table` GC structs with `$hash-ref-impl`/`$hash-set-impl` functions.

## Goals / Non-Goals

**Goals:**
- Fix all 23 WASM hash table/record test failures
- Make hash tables work identically on both CL and WASM hosts
- Preserve the HAMT as an optional library
- Zero changes to the user-facing hash table API

**Non-Goals:**
- Changing the hash table API or semantics
- Implementing persistent/immutable hash maps as the default
- Optimizing WASM hash tables beyond linear scan (fine for typical sizes)

## Decisions

### 1. New core primitive IDs for hash table operations

**Choice:** Assign IDs in the core range (0-99) since hash tables are a fundamental data type needed on all platforms. Use currently-unassigned IDs or reassign from the CL range.

**Primitive mapping:**

| ID | Name | Arity | Description |
|----|------|-------|-------------|
| TBD | `%make-hash-table` | 0 | Create empty mutable hash table |
| TBD | `hash-table?` | 1 | Test if value is a hash table |
| TBD | `hash-ref` | 2-3 | Look up key (optional default) |
| TBD | `hash-set!` | 3 | Set key-value pair (mutating) |
| TBD | `hash-remove!` | 2 | Remove key (mutating) |
| TBD | `hash-has-key?` | 2 | Test if key exists |
| TBD | `hash-keys` | 1 | List of all keys |
| TBD | `hash-values` | 1 | List of all values |
| TBD | `hash-count` | 1 | Number of entries |

The `hash-table` constructor (variadic, takes key-value pairs) stays as an ECE function in the prelude that calls `%make-hash-table` + `hash-set!`.

**Rationale:** Core IDs ensure both hosts implement the same primitives. The existing CL-only `%eq-hash-*` IDs (116-124) remain for backward compatibility but the new core IDs become canonical.

### 2. Equality semantics: eq? for keys

**Choice:** Platform hash tables use `eq?` equality for key lookup, matching the HAMT behavior and CL's `%eq-hash-*`.

On CL, `eq?` maps to `eq`. On WASM, `eq?` maps to `ref.eq`. Interned symbols are identity-equal on both hosts, which is the primary use case (record field names, keyword-style keys).

### 3. HAMT library location

**Choice:** `lib/hamt.scm` with `tests/ece/test-hamt.scm`.

The `lib/` directory is new — it establishes a convention for optional ECE libraries. The HAMT tests verify the pure-ECE implementation independently from the platform hash table tests.

### 4. Prelude changes

**Choice:** Remove all HAMT code from `prelude.scm`. Replace with:
- `hash-table` constructor function (calls `%make-hash-table` + `hash-set!` loop)
- `hash-set` functional update (calls `hash-table?` check + copy + `hash-set!`)
- Any other thin wrappers that add ECE-level convenience over raw primitives

The `define-record` macro already uses `hash-table`/`hash-ref`/`hash-set!` at the API level, so it requires no changes.

## Risks / Trade-offs

- **HAMT was persistent (immutable)** → Platform hash tables are mutable. The HAMT's `hash-set` returned a new table sharing structure. The platform version copies. For ECE's current usage (records, small tables), this is fine. Users needing persistent maps can load `lib/hamt.scm`.

- **Linear scan on WASM** → The WASM `$hash-table` uses parallel arrays with linear scan. O(n) per lookup. Adequate for typical ECE hash tables (5-50 entries). Can upgrade to a proper hash map later if needed.

- **eq? only** → No `equal?`-based hash tables. The HAMT supported `equal?` keys via `hash-code`. Platform primitives use `eq?` only. This matches current usage (symbol keys in records, keyword-style APIs).
