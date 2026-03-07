## Context

ECE already has `map` implemented as an ECE-level function defined via `evaluate` at load time. This pattern works well because higher-order functions need to call ECE procedures through the evaluator's continuation machinery — they can't be simple CL primitives.

## Goals / Non-Goals

**Goals:**
- Add `filter`, `reduce`, and `for-each` as built-in ECE functions
- Follow the same implementation pattern as `map`

**Non-Goals:**
- No CL-level primitive implementations (these must go through the evaluator to call ECE procedures)
- No variadic/multi-list variants (e.g., no `(filter pred list1 list2)`)

## Decisions

### Decision: Implement as ECE functions via `evaluate`
Same approach as `map`: define each function by calling `(evaluate '(define ...))` after `evaluate` is defined. This ensures they work with ECE lambdas, closures, and continuations.

**Alternative considered:** CL primitives with funcall. Rejected because ECE procedures aren't CL functions — they're `(procedure params body env)` lists that need the evaluator's continuation stack.

### Decision: `reduce` takes `(reduce fn init list)`
Three-argument form: function, initial value, list. Folds left. This matches SRFI-1's `fold` semantics and is the most common pattern.

**Alternative considered:** Two-argument `(reduce fn list)` using car as initial value. Rejected because it fails on empty lists and is less general.

### Decision: `for-each` returns nil
`for-each` applies a procedure to each element for side effects and returns nil. This distinguishes it from `map` which collects results.

## Risks / Trade-offs

- [Recursive ECE definitions may hit stack limits on very large lists] → Acceptable for an educational evaluator; same limitation as `map`
