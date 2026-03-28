## Context

Parameters in ECE follow R7RS: `(make-parameter init [converter])`. The converter transforms values before storage. On CL, `ece-make-parameter-value` applies the converter and stores `(parameter (value . converter))`. On WASM, the `$parameter` struct only stores the value — the converter is lost.

The challenge: applying a converter (a compiled ECE procedure) from within a WAT primitive requires re-entering the executor, which is architecturally complex. But applying it from ECE prelude code is trivial — it's just a function call.

## Goals / Non-Goals

**Goals:** Fix the last WASM test failure (329/329)

**Non-Goals:** Changing parameter semantics or the `parameterize` macro

## Decisions

### Prelude-level converter application

**Choice:** The ECE prelude defines `make-parameter` as a wrapper that applies the converter, then calls the raw primitive. Both hosts get identical behavior.

```scheme
(define %raw-make-parameter make-parameter)  ;; capture primitive
(define (make-parameter init . rest)
  (if (null? rest)
      (%raw-make-parameter init)
      (%raw-make-parameter ((car rest) init))))
```

On CL, `ece-make-parameter-value` is simplified to just store the value without applying the converter (the prelude handles it). The converter isn't stored in the parameter — it's only applied once at creation time. This matches the test expectations.

**Note on parameterize:** The `parameterize` macro calls `(param val)` to set and `(param old #t)` to restore. The `apply-parameter` op handles this — it doesn't need the converter because `parameterize` operates on already-converted values. The converter is only needed at `make-parameter` time.
