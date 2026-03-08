## Context

ECE has `reduce` with `(f acc elem)` arg order. Named `let` provides general looping but is verbose for simple cases. No string trimming or numeric clamping exists.

## Goals / Non-Goals

**Goals:**
- Concise forms for common patterns
- Consistent with existing ECE conventions

**Non-Goals:**
- Full CL-style `loop` DSL — keep it simple
- Iterator/generator protocol

## Decisions

### string-trim as CL wrapper primitive
Wraps CL's `string-trim` to strip whitespace (spaces, tabs, newlines) from both ends. Implemented in ece.lisp.

### clamp as prelude function
`(clamp x low high)` — simple min/max combination. Pure ECE in prelude.

### fold aliases reduce, fold-right is new
- `fold` and `fold-left` are aliases for `reduce` (same `(f acc elem)` order)
- `fold-right` is a new function that processes right-to-left with `(f elem acc)` order
- All defined in prelude

### loop macro uses call/cc for break
`loop` expands to a `call/cc` that captures an escape continuation named `break`. The body runs in an infinite loop via named `let`. Calling `(break value)` exits and returns the value.

```scheme
(loop
  (if (= x 0) (break x))
  (set x (- x 1)))
```

Expands roughly to:
```scheme
(call/cc (lambda (break)
  (let go () body... (go))))
```

### collect macro for list comprehension
`(collect (var list-expr) body)` maps body over each element, collecting results. Sugar over `map` + `lambda`.

```scheme
(collect (x (range 10)) (* x x))
;; equivalent to: (map (lambda (x) (* x x)) (range 10))
```

## Risks / Trade-offs

- `break` becomes a bound name inside `loop` — shadows any outer `break` binding. Acceptable tradeoff for clean syntax.
- `collect` is thin sugar over `map` — justified by how common the pattern is.
