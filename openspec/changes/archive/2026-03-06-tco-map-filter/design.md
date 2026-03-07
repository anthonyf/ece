## Context

`map` and `filter` are defined as ECE functions with recursive calls inside `cons`, placing the recursion outside tail position. This means they grow the continuation stack proportionally to list length. `reduce` and `for-each` are already tail-recursive.

## Goals / Non-Goals

**Goals:**
- Make `map` and `filter` tail-recursive using accumulator + `reverse`
- Add `reverse` as a primitive procedure

**Non-Goals:**
- Changing `reduce` or `for-each` (already tail-recursive)
- Multi-list `map` (e.g., `(map + '(1 2) '(3 4))`)

## Decisions

### Decision: Use accumulator + reverse pattern with raw begin/define
Rewrite `map` and `filter` to accumulate results in reverse order via a tail-recursive inner loop, then reverse at the end. This is the standard approach in Scheme implementations.

**Important:** Cannot use named `let` here because the `let` macro internally calls `map` (to extract parameter names and values), which would create an infinite circular expansion: `map` -> `let` -> `map` -> `let` -> ... Instead, use raw `begin`/`define` to define the inner loop function — this is exactly what named `let` would expand to, but bypasses the `let` macro.

`map` becomes:
```scheme
(define (map f lst)
  (begin
    (define (loop rest acc)
      (if (null? rest)
          (reverse acc)
          (loop (cdr rest) (cons (f (car rest)) acc))))
    (loop lst '())))
```

`filter` becomes:
```scheme
(define (filter pred lst)
  (begin
    (define (loop rest acc)
      (if (null? rest)
          (reverse acc)
          (if (pred (car rest))
              (loop (cdr rest) (cons (car rest) acc))
              (loop (cdr rest) acc))))
    (loop lst '())))
```

### Decision: Implement reverse as a CL primitive
`reverse` is a trivial wrapper around CL's `cl:reverse`. Implementing it as a primitive avoids bootstrapping issues (we need `reverse` to define `map`, but can't use `map` to define `reverse` efficiently).

## Risks / Trade-offs

- [Accumulator + reverse allocates the list twice] → Acceptable; same approach used by most Scheme implementations. The alternative (mutation-based) is more complex and not idiomatic.
