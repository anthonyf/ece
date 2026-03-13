## Context

ECE primitives map directly to CL functions. When CL functions receive wrong types, they signal CL conditions that bypass ECE's `raise`/`guard` exception system. The dynamic-wind change gave ECE a full R7RS exception system, but CL-originated errors still escape it.

Benchmarking showed that wrapping a primitive in an ECE function with type checks has negligible performance impact — the executor's instruction dispatch dominates.

## Goals / Non-Goals

**Goals:**
- All user-facing type errors from primitives are catchable by `guard`
- Error messages are ECE-native and user-friendly (e.g., `"car: not a pair"` not CL's `"Value of 5 in (CAR 5) is 5, not a LIST."`)
- Zero executor or bridging changes — pure ECE prelude solution
- CL errors from user code are effectively eliminated

**Non-Goals:**
- Wrapping primitives that can't type-error (`cons`, `list`, `null?`, `pair?`, `number?`, `eq?`, `equal?`, etc.)
- Catching CL errors from internal runtime operations (`lookup-variable-value`, corrupt instructions) — these are bugs, not user errors
- Variadic type checking for `+`, `-`, `*` (CL's `+` already accepts varargs; ECE's wrapper checks each arg)

## Decisions

### 1. Rename-and-wrap in prelude, not CL wrappers

**Decision**: Rename primitives to `%raw-` prefix in `*primitive-procedures*` and define safe wrappers in `src/prelude.scm`.

**Alternative considered**: CL-side wrapper functions that type-check and signal a special condition. Rejected because (a) CL errors still need bridging to reach ECE's `raise`, and (b) it keeps type-checking logic in the CL kernel, working against kernel minimization.

**Alternative considered**: Sentinel return value from `apply-primitive-procedure` with executor-side checking. Rejected as unnecessarily complex — prevents the error rather than catching it.

### 2. Use `apply` for variadic arithmetic

**Decision**: Arithmetic wrappers accept rest args and use `(apply %raw-+ args)` after checking all args are numbers. This preserves CL's variadic behavior for `+`, `-`, `*`, and comparison chains.

```scheme
(define (+ . args)
  (for-each (lambda (a)
    (if (not (number? a))
        (error "not a number" a))) args)
  (apply %raw-+ args))
```

### 3. Fixed-arity wrappers for list/vector/string/char ops

**Decision**: `car`, `cdr`, `vector-ref`, `char=?`, etc. take a known number of arguments. Use simple `if`/`and` checks.

```scheme
(define (car x)
  (if (pair? x) (%raw-car x)
      (error "car: not a pair" x)))
```

### 4. Division-by-zero check in `/`

**Decision**: The `/` wrapper checks for zero divisor in addition to type checking, since CL's `DIVISION-BY-ZERO` is the most common CL error from ECE code.

### 5. Error message format

**Decision**: Messages follow the pattern `"<operation>: <problem>"` with the offending value as an irritant. Examples:
- `(error "car: not a pair" x)`
- `(error "+: not a number" a)`
- `(error "/: division by zero")`

## Risks / Trade-offs

- **[Slight consing increase]** Variadic wrappers use `for-each` on the args list. → Acceptable; benchmarks show negligible impact.
- **[Prelude ordering]** Wrappers must be defined after `error`, `raise`, `for-each`, and `apply` exist. → Place wrappers at end of prelude, after all dependencies.
- **[Self-hosted compiler uses primitives]** `compiler.scm` may call `+`, `car`, etc. After renaming, these resolve to the safe wrappers, which is correct — the compiler should also get type-safe operations.
- **[Existing tests reference primitive behavior]** Some rove tests may test CL-level error behavior for primitives. → Update to test ECE error-object behavior instead.
