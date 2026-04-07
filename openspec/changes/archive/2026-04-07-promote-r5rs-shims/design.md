## Context

ECE provides `member` and `assoc` (both use `equal?` for comparison) in the prelude, and type predicates like `number?`, `string?`, `pair?` as CL primitives. However, four standard R5RS functions are missing and are instead defined as local shims in conformance test files:

- `memq` / `assq` — `eq?`-based variants of `member` / `assoc`
- `list?` — proper list predicate
- `procedure?` — callable object predicate

## Goals / Non-Goals

**Goals:**
- Add `memq`, `assq`, `list?` to the prelude as standard ECE functions
- Add `procedure?` as a CL primitive that checks all three callable tags
- Remove all shim definitions from conformance test files
- Close issue #108

**Non-Goals:**
- Adding `memv` / `assv` (eqv?-based variants) — can be done later if needed
- Adding optional comparator arguments to `member` / `assoc` (R7RS extension)
- Changing how type tags work internally

## Decisions

### 1. `memq` and `assq` in ECE prelude

Define alongside `member` and `assoc` in `src/prelude.scm`. Identical structure but using `eq?` instead of `equal?`:

```scheme
(define (memq x lst)
  (if (null? lst) #f
      (if (eq? x (car lst)) lst
          (memq x (cdr lst)))))

(define (assq key alist)
  (if (null? alist) #f
      (if (eq? key (car (car alist))) (car alist)
          (assq key (cdr alist)))))
```

These go in the prelude (ECE code) rather than as CL primitives — consistent with the kernel minimization principle.

### 2. `list?` in ECE prelude

```scheme
(define (list? x)
  (if (null? x) #t
      (if (pair? x) (list? (cdr x))
          #f)))
```

Simple recursive check. No cycle detection (matches R5RS behavior — R7RS adds cycle detection but that's a non-goal). Placed in prelude near the list search functions.

Note: `list?` cannot use `cond` because `cond` is a macro defined later in the prelude. Use nested `if` instead.

### 3. `procedure?` as a CL primitive

Unlike the other three, `procedure?` needs to inspect internal type tags. Implementing it in ECE would require exposing tag symbols, which defeats the purpose of the predicate abstraction. Instead, add `ece-procedure?` to `src/runtime.lisp` using the CL-internal predicates:

```lisp
(defun ece-procedure? (x)
  (scheme-bool (or (compiled-procedure-p x)
                   (primitive-procedure-p x)
                   (continuation-p x))))
```

Register as a primitive in `boot-env.scm`. This replaces the fragile shim that extracted tags from live objects.

### 4. Shim removal

Delete shim definitions from:
- `tests/conformance/chibi-r5rs.scm` (lines 11-31: `memq`, `list?`, `assq`, `procedure?` + tag extraction)
- `tests/conformance/r5rs-pitfall.scm` (lines 15-20: `procedure?` + tag extraction)

## Risks / Trade-offs

- **Risk**: `list?` without cycle detection will loop on circular lists.
  -> **Mitigation**: This matches R5RS. Cycle-safe `list?` is a separate enhancement if needed.

- **Risk**: Removing shims could break tests if the new definitions have subtle differences.
  -> **Mitigation**: The implementations are identical in behavior. Run conformance tests to verify.
