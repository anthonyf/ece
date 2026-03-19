## Context

ECE needs to serialize arbitrary values (including continuations with space-qualified addresses) to files and read them back. The old serializer was ~200 lines of CL that walked ECE data structures. The new implementation should be written in ECE to minimize the CL kernel, and use s-expressions for portability and debuggability.

## Goals / Non-Goals

**Goals:**
- Round-trip any ECE value through save/load
- Handle all data types: numbers, strings, chars, booleans, symbols, pairs, vectors, hash tables, compiled procedures, continuations, primitives
- Preserve space-qualified addresses in compiled procedures and continuations
- Store primitives by name (not numeric ID) for rebuild portability
- Handle shared structure and cycles (via a ref/def tagging scheme)
- Written entirely in ECE

**Non-Goals:**
- Binary format optimization (s-expressions are fine for game saves)
- Streaming/incremental serialization
- Cross-platform portability (CL-specific details like keyword symbols are acceptable)

## Decisions

### 1. Tagged s-expression format

**Choice:** Each special type serializes as a tagged list: `(#:type field1 field2 ...)`. Plain types (numbers, strings, booleans, symbols) serialize as themselves.

```scheme
;; Compiled procedure
(#:compiled-procedure (prelude . 4523) <serialized-env>)

;; Continuation
(#:continuation <serialized-stack> (compiler . 891))

;; Primitive by name
(#:primitive map)

;; Hash table
(#:hash-table (key1 val1) (key2 val2) ...)

;; Vector
(#:vector el0 el1 el2 ...)
```

**Why:** S-expressions are readable by the ECE reader. Tagged lists are unambiguous — `#:type` uses uninterned symbols (gensym-style) which can't collide with user data. Simple to implement in ECE with `write-to-string` + custom serializer for special types.

### 2. Shared structure via #:ref / #:def

**Choice:** First pass identifies objects that appear more than once. Second pass writes `(#:def N <value>)` on first occurrence and `(#:ref N)` on subsequent references. This handles DAGs and cycles.

```scheme
;; Shared list
(#:def 0 (1 2 3))
;; ... later ...
(#:ref 0)
```

**Why:** Continuations capture stack copies that share structure with environments. Without shared-structure handling, serialized continuations would be enormous (duplicated environments) or infinite (circular references in letrec).

### 3. Primitives stored by name

**Choice:** Primitive values `(primitive <id>)` serialize as `(#:primitive <name>)` where name is the symbol from the primitive name table. On load, the name is looked up in the current environment to find the current ID.

**Why:** Numeric IDs can change between rebuilds (new primitives added, IDs renumbered). Symbol names are stable.

### 4. Environment serialization

**Choice:** Environments are serialized as lists of frames. Hash frames serialize as alists. Vector frames serialize as vectors. Only the reachable portion of the environment is serialized (the closure's env chain, not the entire global env).

**Why:** Compiled procedures capture environment closures. Serializing the full global env would be enormous. The closure's env chain contains only the frames the procedure needs.

### 5. Implementation in ECE, not CL

**Choice:** The serializer and deserializer are ECE functions defined in `src/prelude.scm` (or a new `src/serialization.scm`). They use `write-to-string-flat` for atom serialization and the ECE reader for deserialization.

**Why:** Minimizes the CL kernel. The serializer only walks ECE data structures — no CL-specific logic needed. Writing in ECE also means the serializer is available to ECE programs directly.

## Risks / Trade-offs

**[Performance]** S-expression serialization is slower than binary. Mitigation: game saves are small (a few KB of continuation + environment). Not a bottleneck.

**[Shared structure detection]** First-pass identity scan requires walking the entire value graph. Mitigation: ECE values are typically small trees. Deep continuations with large environments are the worst case but still manageable.

**[Global env in closures]** Some closures capture the global environment frame. Serializing this would serialize everything. Mitigation: detect the global frame and serialize a sentinel `(#:global-env)` instead. On load, reconnect to the current global env.
