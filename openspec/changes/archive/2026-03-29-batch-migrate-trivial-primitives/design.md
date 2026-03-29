## Context

ECE has seven core primitives that are purely algorithmic — they use only other core primitives and need no host-specific type representations. CL implements them as trivial one-liner wrappers. WASM implements them as short WAT functions. All can be expressed in ~1-5 lines of ECE each.

Some WAT functions have internal callers beyond the primitive dispatch:
- `$prim-string-eq` is called by `$prim-equal` (the WAT equal? implementation, still used internally)
- `$prim-string-lt` is called by `$prim-string-gt`
- `$prim-list-to-vector` is called by the `vector` primitive (ID 51) dispatch

## Goals / Non-Goals

**Goals:**
- Implement all 7 primitives in ECE prelude
- Remove from CL host completely
- Remove from WASM primitive dispatch
- Follow two-pass bootstrap migration pattern

**Non-Goals:**
- Removing WAT functions that have internal callers (separate change when callers are also migrated)
- Performance optimization (these are not hot-path operations)
- Migrating `string->number` or `write-to-string` (separate, more complex changes)

## Decisions

### Decision 1: Char comparisons via char->integer

**Choice**: `(define (char=? a b) (= (char->integer a) (char->integer b)))` and same for `char<?` with `<`.

**Rationale**: `char->integer` (43) and `=`/`<` (22/23) are irreducible core primitives. One-liner derivations, no alternatives worth considering.

### Decision 2: String comparisons via index loop

**Choice**: Iterative character-by-character comparison using `string-ref`, `string-length`, and `char=?`/`char<?`.

```scheme
(define (string=? a b)
  (and (= (string-length a) (string-length b))
       (let loop ((i 0))
         (or (= i (string-length a))
             (and (char=? (string-ref a i) (string-ref b i))
                  (loop (+ i 1)))))))

(define (string<? a b)
  (let ((la (string-length a)) (lb (string-length b)))
    (let loop ((i 0))
      (cond
        ((= i la) (< la lb))
        ((= i lb) #f)
        ((char<? (string-ref a i) (string-ref b i)) #t)
        ((char<? (string-ref b i) (string-ref a i)) #f)
        (else (loop (+ i 1)))))))

(define (string>? a b) (string<? b a))
```

**Rationale**: Standard lexicographic comparison. `string>?` delegates to `string<?` with swapped args (same pattern as the WAT `$prim-string-gt`).

### Decision 3: vector->list builds in reverse, then reverses

**Choice**: Iterate from last index to 0, consing each element, producing the list in correct order without needing `reverse`.

```scheme
(define (vector->list vec)
  (let loop ((i (- (vector-length vec) 1)) (acc '()))
    (if (< i 0) acc
        (loop (- i 1) (cons (vector-ref vec i) acc)))))
```

**Rationale**: Building from the end avoids needing `reverse` (which itself would need `vector->list` to exist first — circular dependency risk). Single pass, O(n).

### Decision 4: list->vector counts length first

**Choice**: Two-pass — count list length, allocate vector, fill.

```scheme
(define (list->vector lst)
  (let* ((len (length lst))
         (vec (make-vector len)))
    (let loop ((i 0) (rest lst))
      (if (= i len) vec
          (begin (vector-set! vec i (car rest))
                 (loop (+ i 1) (cdr rest)))))))
```

**Rationale**: `make-vector` requires a size upfront. Alternatives (growable vector, repeated vector-set! with resize) would require host-level vector resize primitives that don't exist.

### Decision 5: Placement in prelude

**Choice**:
- `char=?` and `char<?` go in the "Character predicates" section (after existing char predicates)
- `string=?`, `string<?`, `string>?` go in the "String operations" section (before existing string functions that may depend on them)
- `vector->list`, `list->vector` go after the "Higher-order functions" section (they need `length` which is defined there)

**Rationale**: Respect dependency ordering. `string=?` depends on `char=?`. `list->vector` depends on `length`. All must precede any code that calls them.

### Decision 6: Keep WAT internal functions

**Choice**: Keep `$prim-string-eq`, `$prim-string-lt`, `$prim-string-gt`, `$prim-list-to-vector` as WAT internal functions. Only remove the dispatch entries.

**Rationale**: Same pattern as `$prim-number-to-string` — internal callers in WAT can't easily invoke ECE-compiled code. `$prim-string-eq` is called by `$prim-equal`; `$prim-list-to-vector` is called by the `vector` (ID 51) dispatch. Full removal is blocked until those callers are also migrated.

## Risks / Trade-offs

**[Low] Performance regression for string comparison** → ECE `string=?` does per-character comparison through primitive dispatch (string-ref, char->integer, =) vs a single WAT loop. For short strings (symbol names, test assertions), the overhead is negligible. Hot-path string comparison (reader, hash lookup) uses `eq?` on interned symbols, not `string=?`.

**[Low] list->vector two-pass overhead** → Counts list length first, then fills. Extra traversal is O(n) on a list that's already O(n) to fill. Acceptable.

**[None] Bootstrap ordering** → All 7 primitives depend only on existing core primitives. No circular dependencies.
