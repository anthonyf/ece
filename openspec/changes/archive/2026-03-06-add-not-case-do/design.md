## Context

ECE has macros (`cond`, `let`, `let*`, `letrec`, `and`, `or`, `when`, `unless`) and named `let` for iteration. Adding `case` and `do` rounds out the standard R5RS derived forms.

## Goals / Non-Goals

**Goals:**
- Implement `case` as a macro expanding to `cond` with `eq?`/`equal?` tests
- Implement `do` as a macro expanding to named `let`

**Non-Goals:**
- `case-lambda` (different feature)
- Multi-list `do` variants

## Decisions

### Decision: `case` expands to nested `cond`
`case` evaluates a key expression once, then tests each clause's datum list. Uses `equal?` for comparison to support numbers, symbols, and strings.

```scheme
(case (+ 1 1)
  ((1) "one")
  ((2 3) "two or three")
  (else "other"))
```

Expands conceptually to:
```scheme
(let ((key (+ 1 1)))
  (cond
    ((or (equal? key 1)) "one")
    ((or (equal? key 2) (equal? key 3)) "two or three")
    (else "other")))
```

**Important:** Cannot use `let` in the expansion because `let` macro calls `map`, and `map`/`let` have a circular dependency issue. Must use raw `begin`/`define` to bind the key, or use a lambda application directly: `((lambda (key) (cond ...)) key-expr)`.

### Decision: `do` expands to named `let`
R5RS `do` syntax:
```scheme
(do ((var init step) ...)
    (test result ...)
  body ...)
```

Expands to:
```scheme
(let loop ((var init) ...)
  (if test
      (begin result ...)
      (begin body ... (loop step ...))))
```

**Important:** Same circular dependency concern — `do` expanding to named `let` is fine because `do` doesn't call `map`. The `let` macro uses `map` internally, but `do`'s expansion is the input to `let`, not something `let` calls during expansion. Named `let` expands to `begin`/`define`, and the body of the defined function contains the `do`-generated code. No circularity.

## Risks / Trade-offs

- [`case` uses `equal?` not `eqv?`] → ECE doesn't have `eqv?`. `equal?` is correct for all datum types we support.
- [`case` key must be evaluated only once] → Handled by binding to a temporary variable via lambda application.
