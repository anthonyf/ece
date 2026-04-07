## Context

runtime.lisp defines two layers of predicates and accessors for ECE's tagged-list values (compiled-procedure, primitive, continuation, parameter):

1. **CL-internal** (`compiled-procedure-p`, `compiled-procedure-entry`, etc.) — return CL booleans, used by the executor and dispatch code
2. **ECE-facing** (`ece-compiled-procedure?`, `ece-compiled-procedure-entry`, etc.) — return Scheme booleans, exposed as ECE primitives

Despite having both layers, ~15 sites in runtime.lisp bypass them entirely with raw `(eq (car x) '|compiled-procedure|)` checks and `(cadr ...)` slot access. The ECE-facing predicates also duplicate the CL-internal tag-check logic instead of delegating.

## Goals / Non-Goals

**Goals:**
- Every internal CL site uses the CL-facing predicates and accessors — no raw tag checks or slot access
- ECE-facing predicates delegate to CL-facing predicates (single source of truth for tag checks)
- Add missing accessors where raw `(cadr ...)` is used on a known structure type
- Close issue #107

**Non-Goals:**
- Changing the tagged-list representation to `defstruct` (separate effort)
- Adding new ECE-visible predicates or accessors (only CL-internal additions)
- Modifying the parameter representation or accessor API beyond adding a `parameter-cell` accessor

## Decisions

### 1. New CL-internal accessors

Add these to the existing accessor block (near line 1320):

- `primitive-procedure-id (proc)` → `(cadr proc)` — extracts the numeric ID or symbol name from a primitive. Replaces raw `(cadr proc)` in `apply-primitive-procedure` and `format-ece-proc`.
- `parameter-cell (param)` → `(cadr param)` — extracts the `(value . converter)` cons cell. Replaces raw `(cadr param)` in `parameter-ref`, `parameter-set!`, `parameter-raw-set!`.
- `procedure-name (proc)` → `(gethash (compiled-procedure-entry proc) *procedure-name-table*)` — looks up a compiled procedure's name. Replaces the raw hash-table lookup in `format-ece-proc`. Falls back to checking `(cdr entry)` for qualified entries.

### 2. ECE predicate consolidation

Rewrite the ECE-facing predicates to delegate:

```lisp
(defun ece-compiled-procedure? (x) (scheme-bool (compiled-procedure-p x)))
(defun ece-primitive? (x)           (scheme-bool (primitive-procedure-p x)))
(defun ece-continuation? (x)        (scheme-bool (continuation-p x)))
```

This ensures the tag symbols (`|compiled-procedure|`, `|primitive|`, `|continuation|`) are defined in exactly one place each.

### 3. Refactoring sites

| Site | Line(s) | Current | After |
|------|---------|---------|-------|
| `format-ece-proc` | 275, 288 | raw `eq` + `cadr` | predicates + `compiled-procedure-entry`, `primitive-procedure-id` |
| `extract-ece-backtrace` | 318-321 | raw `or`/`eq` | `(or (compiled-procedure-p ...) (primitive-procedure-p ...))` |
| `apply-primitive-procedure` | 1386 | `(cadr proc)` | `primitive-procedure-id` |
| `do-continuation-winds` | 1455 | `(cadddr cont)` | `ece-continuation-winds` (already exists) |
| `parameter-ref` | 1288 | `(car (cadr param))` | `(car (parameter-cell param))` |
| `parameter-set!` | 1292 | `(cadr param)` | `(parameter-cell param)` |
| `parameter-raw-set!` | 1304 | `(cadr param)` | `(parameter-cell param)` |
| `ece-compiled-procedure?` | 1134 | duplicated tag check | delegate to `compiled-procedure-p` |
| `ece-continuation?` | 1138 | duplicated tag check | delegate to `continuation-p` |
| `ece-primitive?` | 1141 | duplicated tag check | delegate to `primitive-procedure-p` |

### 4. Definition order

The CL-internal predicates and accessors (`compiled-procedure-p`, etc.) are currently defined after the ECE-facing primitives block. The ECE-facing predicates need to call the CL-internal ones, so the CL-internal predicates must be defined first. Move the CL-internal predicate/accessor block above the ECE-facing primitives block if needed, or simply ensure the ECE predicates are defined after the CL predicates (which they currently are — ECE primitives are at ~1134, CL predicates at ~1325). Reorder so CL predicates come first.

## Risks / Trade-offs

- **Risk**: Reordering function definitions could cause forward-reference issues.
  → **Mitigation**: CL does not require forward declarations for `defun`. The only requirement is that functions are defined before they're *called at load time* (via `defparameter` initializers, etc.). All these functions are called at runtime, not load time.

- **Risk**: `procedure-name` accessor introduces coupling to `*procedure-name-table*`.
  → **Mitigation**: This table is already used in `format-ece-proc`. The accessor centralizes the lookup pattern rather than adding new coupling.
