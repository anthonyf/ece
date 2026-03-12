## Context

After the shrink-kernel change, the CL runtime is 1,489 lines with 140 registered primitives. Analysis shows ~35 primitives are used internally by ECE source files; the rest serve user code. Many of the user-facing primitives are trivial compositions of bedrock operations and could be ECE functions instead.

ECE hash tables are already alist-based structures `(:hash-table (k . v) ...)` — the CL wrappers just manipulate cons cells, which ECE can do natively. Derived predicates like `not`, `zero?`, `<=` are one-liners. List accessors like `cadr` are direct compositions of `car`/`cdr`.

The prelude currently starts with `map` (which uses `reverse`), so moved functions must be inserted at the top in dependency order.

## Goals / Non-Goals

**Goals:**
- Move ~33 primitives from CL to ECE definitions in prelude.scm
- Reduce CL kernel by ~90 lines and ~33 primitive registrations
- Maintain all existing behavior and pass all tests
- Keep boot order correct (definitions before first use)

**Non-Goals:**
- Moving I/O primitives (need host streams)
- Moving string/char primitives (need host string representation)
- Moving vector primitives beyond predicates (need host array ops)
- Moving compiler-internal `%`-prefixed primitives (need host instruction vector access)
- Optimizing performance of moved primitives

## Decisions

### 1. What moves to ECE

**Hash table ops (10):** `hash-table`, `hash-table?`, `hash-ref`, `hash-set!`, `hash-set`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-remove!`

Rationale: These are pure alist manipulation on `(:hash-table . alist)` structures. No host capability needed.

**Derived predicates (8):** `not`, `zero?`, `even?`, `odd?`, `positive?`, `negative?`, `<=`, `>=`

Rationale: Each is a one-liner composing existing bedrock ops (`=`, `<`, `>`, `modulo`).

**Math helpers (3):** `abs`, `min`, `max`

Rationale: Trivial compositions of `<`, `>`, `-`.

**List accessors (6):** `cadr`, `caddr`, `caar`, `cddr`, `list-ref`, `list-tail`

Rationale: Direct compositions of `car`/`cdr`. `list-ref` and `list-tail` are CL wrappers that exist only to reverse argument order vs `nth`/`nthcdr`.

**List functions (5):** `reverse`, `length`, `append`, `member`, `assoc`

Rationale: Standard recursive list operations. `member` and `assoc` use `equal?` for comparison.

**Total: 32 primitives**

### 2. What stays in CL

**`equal?`** — Kept as CL primitive. Reimplementing structural equality in ECE requires dispatching on every type (pair, string, vector, number, char, symbol, hash-table). CL's `equal` handles all of these natively and correctly. The ECE version would be slower and more complex for no portability gain (any WASM host will need a native `equal` too).

**`length`** — Kept as CL primitive. CL's `length` is generic (works on lists, strings, vectors). Moving it to ECE would either break genericity or require type-dispatching logic. Separate `string-length` and `vector-length` primitives exist for explicit use.

**`list`** — Kept as CL primitive. It's variadic and trivial in CL. An ECE version `(define (list . items) items)` works but introduces cold-boot risk since rest params must be fully working.

**All I/O, ports, strings, chars, vectors, compiler-internals, bitwise ops** — Kept. These genuinely need host capabilities.

### 3. Prelude boot order

New definitions must appear before existing code that uses them. Insert a new section at the top of prelude.scm:

```
;; 1. List accessors (used everywhere)
;;    cadr, caddr, caar, cddr
;;
;; 2. Core list functions (used by map, filter, etc.)
;;    reverse, length, append, assoc, member, list-ref, list-tail
;;
;; 3. Derived predicates (used by macros like case, assert)
;;    not, zero?, even?, odd?, positive?, negative?, <=, >=
;;
;; 4. Math helpers
;;    abs, min, max
;;
;; 5. Hash table operations (used by define-record)
;;    hash-table, hash-table?, hash-ref, hash-set!, hash-set,
;;    hash-has-key?, hash-keys, hash-values, hash-count, hash-remove!
;;
;; 6. Existing prelude (map, reduce, filter, macros, etc.)
```

### 4. Hash table constructor uses rest params

`hash-table` currently accepts variadic key-value pairs: `(hash-table 'a 1 'b 2)`. The ECE version needs rest params:

```scheme
(define (hash-table . pairs)
  (cons ':hash-table (build-alist pairs)))
```

Where `build-alist` groups pairs of args into `(key . value)` cons cells. This relies on rest params working correctly (they do — compiler handles them).

### 5. Removal from runtime.lisp

For each moved primitive:
1. Remove from `*primitive-procedures*` alist (if present there)
2. Remove from `*wrapper-primitives*` alist (if present there)
3. Delete the CL wrapper function (if it has one beyond a direct CL mapping)

Some primitives like `cadr` map directly to CL symbols and have no wrapper function to delete — they only need removal from the registration alist.

## Risks / Trade-offs

**[Performance regression on CL host]** → Acceptable. Moved primitives go through the register machine instead of native CL calls. For interactive fiction workloads this is negligible. For WASM, everything is interpreted anyway.

**[Boot order breakage]** → Mitigated by careful ordering. All new definitions must precede any code that calls them. `reverse` and `length` must appear before `map`/`filter`.

**[hash-table constructor rest params]** → Low risk. Rest params are well-tested. The constructor pattern `(define (hash-table . pairs) ...)` is standard.

**[member/assoc use equal? which stays in CL]** → No issue. The ECE definitions of `member` and `assoc` will call `equal?` which remains a CL primitive. Works fine.

**[clamp uses min/max]** → `clamp` at line 236 uses `min` and `max`. These must be defined before `clamp`. The new section at the top of prelude handles this.
