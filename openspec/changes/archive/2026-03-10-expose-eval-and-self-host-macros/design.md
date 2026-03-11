## Context

ECE has a metacircular compiler (`compiler.scm`) that handles all compilation after bootstrap. However, macro expansion still delegates to CL: `mc-expand-macro-at-compile-time` calls the `expand-macro` primitive, which calls CL's `expand-macro-at-compile-time`, which calls CL's `evaluate` (which is `compile-and-go`).

The ECE compiler already has `mc-compile-and-go` which does exactly the same thing — compile, assemble, execute. So the delegation is unnecessary.

Meanwhile, `eval` is not exposed to user code at all despite the machinery being available.

## Goals / Non-Goals

**Goals:**
- Expose `eval` to ECE user code
- Make macro expansion self-hosted — the ECE compiler expands macros using its own `mc-compile-and-go`
- After this change, the CL compiler is only needed during cold bootstrap

**Non-Goals:**
- Removing the CL compiler from the codebase (still needed for cold bootstrap)
- Changing how macros are stored or defined
- Pre-compiling macro transformers (they remain as `(params body env)` tuples)

## Decisions

### 1. `eval` is defined in `compiler.scm` as a simple alias

```scheme
(define (eval expr) (mc-compile-and-go expr))
```

This goes in `compiler.scm` after `mc-compile-and-go` is defined, since it depends on the compiler. It's a one-liner — `eval` compiles the expression and executes it.

**Alternative considered:** Exposing CL's `evaluate` as a primitive. Rejected — `mc-compile-and-go` already does the same thing and keeps the dependency chain clean (ECE code calling ECE compiler).

### 2. Self-host `mc-expand-macro-at-compile-time` inline

Replace the current delegation:
```scheme
(define (mc-expand-macro-at-compile-time macro-def operands)
  (expand-macro macro-def operands))
```

With direct implementation:
```scheme
(define (mc-expand-macro-at-compile-time macro-def operands)
  (let ((params (car macro-def))
        (body (cadr macro-def))
        (macro-env (caddr macro-def)))
    (let ((expansion-env (extend-environment params operands macro-env)))
      (let loop ((exprs body) (result '()))
        (if (null? exprs)
            result
            (loop (cdr exprs) (mc-compile-and-go (car exprs) expansion-env)))))))
```

This mirrors what CL's `expand-macro-at-compile-time` does: extend environment with params bound to operands, then evaluate each body expression in that environment via compile-and-go. The last result is the expansion.

**Key requirement:** `mc-compile-and-go` must accept an optional environment argument (currently it may only use `*global-env*`). Need to check and potentially add this.

### 3. `extend-environment` needs to be available to ECE code

The macro expander calls `extend-environment` to bind macro parameters to operands. This is currently a CL function in `runtime.lisp`. It's already used by the register machine executor (as an `(op extend-environment)` operation), so it's accessible via the operation dispatch table. We need to expose it as a callable primitive.

## Risks / Trade-offs

- [Circularity] A macro that uses `eval` inside its body could trigger reentrant compilation. This already works today (CL's `evaluate` is reentrant via `compile-and-go`), so no new risk. The instruction vector is append-only, so concurrent appends are safe.
- [Bootstrap order] `eval` and the self-hosted expander must be defined after `mc-compile-and-go` in `compiler.scm`. This is already the natural position — macro expansion is called by `mc-compile`, and `mc-compile-and-go` calls `mc-compile`.
