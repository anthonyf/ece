## Context

The serializer in `prelude.scm` detects types via `(pair? obj) + (eq? (car obj) 'compiled-procedure)`. On CL, all ECE types are represented as tagged pairs. On WASM, compiled-procedure/continuation/primitive are WasmGC structs — opaque to ECE code. The serializer needs primitives to introspect them.

The deserializer reconstructs values via `(list 'compiled-procedure entry env)`. On WASM, this creates a pair (wrong) instead of a `$compiled-proc` struct. It needs reconstruction primitives.

## Goals / Non-Goals

**Goals:**
- `serialize-value` / `deserialize-value` work on WASM
- `save-continuation!` / `load-continuation` work on WASM (localStorage-backed)
- Minimal changes to the serializer/deserializer ECE code
- Same serialization format on both runtimes (portable save files)

**Non-Goals:**
- Changing the serialization format
- Serializing WASM-specific handles or JS references
- Cross-runtime deserialization (CL save → WASM load) — different struct representations

## Decisions

### 1. New primitives (add to primitives.def as core)

**Type predicates** (promote from ops to callable primitives):
| ID | Name | Arity | Notes |
|----|------|-------|-------|
| 155 | compiled-procedure? | 1 | Wraps `$is-compiled-proc` |
| 156 | continuation? | 1 | Wraps `$is-continuation` |
| 157 | primitive? | 1 | Wraps `$is-primitive` |

**Type accessors** (new primitives):
| ID | Name | Arity | Notes |
|----|------|-------|-------|
| 158 | compiled-procedure-entry | 1 | Returns `(space-id . pc)` pair |
| 159 | compiled-procedure-env | 1 | Returns env frame |
| 160 | continuation-stack | 1 | Returns saved stack |
| 161 | continuation-conts | 1 | Returns saved continue |
| 162 | %primitive-id-of | 1 | Returns numeric ID from primitive struct |

**Reconstruction** (new primitives):
| ID | Name | Arity | Notes |
|----|------|-------|-------|
| 163 | %make-compiled-procedure | 2 | `(entry env) → $compiled-proc` |
| 164 | %make-continuation | 2 | `(stack conts) → $continuation` |

**Identity hash tables** (promote from cl to core):
| ID | Name | Arity | Notes |
|----|------|-------|-------|
| 116 | %eq-hash-table | 0 | Already in def as cl — change to core |
| 117 | %eq-hash-ref | 2 | Already in def as cl — change to core |
| 118 | %eq-hash-set! | 3 | Already in def as cl — change to core |

**Helpers** (promote from cl to core):
| ID | Name | Arity | Notes |
|----|------|-------|-------|
| 138 | %primitive-name | 1 | Already in def as cl — change to core |
| 139 | %primitive-id | 1 | Already in def as cl — change to core |
| 140 | %global-env-frame | 0 | Already in def as cl — change to core |
| 121 | %hash-frame? | 1 | Already in def as cl — change to core |

### 2. Identity hash tables on WASM

Use the existing `$hash-table` WasmGC struct with a different comparison strategy. The current hash tables use string hashing on symbol names. For eq-hash, use a unique object ID.

Approach: assign each GC object a monotonic ID on first insertion (using a side table or the handle system). Store entries as `(id → value)` in the hash table. Lookup: get the object's ID, search for it.

Simpler approach: use a linear alist `((obj . val) ...)` with `ref.eq` for comparison. For the serializer's use case (~100s of entries), linear scan is fast enough.

### 3. Serializer changes (prelude.scm)

The serializer's `ser-compound` function currently checks:
```scheme
((and (pair? obj) (eq? (car obj) 'compiled-procedure)) ...)
```

Replace with platform-portable checks:
```scheme
((compiled-procedure? obj)
 (string-append "(%ser/compiled-procedure" (ser-entry (compiled-procedure-entry obj)) " " (ser (compiled-procedure-env obj)) ")"))
```

### 4. Deserializer changes (prelude.scm)

Replace tagged pair reconstruction:
```scheme
;; Old: (list 'compiled-procedure entry env)
;; New:
(%make-compiled-procedure entry (deser env))
```

On CL, `%make-compiled-procedure` just creates `(list 'compiled-procedure entry env)`. On WASM, it creates a `$compiled-proc` struct. Same interface, different implementation.

### 5. CL runtime additions

Add trivial CL implementations for the new primitives:
- `%make-compiled-procedure` → `(list 'compiled-procedure entry env)`
- `%make-continuation` → `(list 'continuation stack conts)`
- Type predicates already exist on CL (they check the tagged pair)

## Risks / Trade-offs

- **ID allocation for eq-hash**: Using alist with `ref.eq` is O(n) per lookup. Acceptable for serializer (~100s entries). If performance matters later, switch to handle-table-based hashing.
- **Cross-runtime portability**: Save files from CL won't load on WASM (different struct representations). This is acceptable — the serialization format is the same, but the deserialized values are runtime-specific.
- **Entry address validity**: A deserialized compiled-procedure has a `(space-id . pc)` from a previous session. The space must still be loaded with the same code at the same PC. This is inherently fragile but matches how CL save/load works.
