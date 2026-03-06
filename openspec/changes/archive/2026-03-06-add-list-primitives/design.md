## Context

Primitives are added via two parallel lists (`*primitive-procedure-names*` and `*primitive-procedure-objects*`) that map names to `(primitive <cl-function>)` wrappers. Simple CL functions like `cadr` can be added directly.

`map` is best implemented as an ECE function using `define` since it needs to call ECE procedures, and the evaluator's `apply` mechanism isn't accessible from CL primitives.

`apply` cannot be a primitive because CL primitives run outside the evaluator's continuation stack. A primitive `apply` would need to call `evaluate` recursively, breaking TCO and `call/cc` across the boundary. Instead, `apply` is implemented as a special form with its own continuation handlers.

## Goals / Non-Goals

**Goals:**
- Add list access shortcuts: `cadr`, `caddr`, `caar`, `cddr`
- Add `append`, `length`, `pair?` as CL-backed primitives
- Add `map` as an ECE-defined function
- Add `apply` to call procedures with argument lists

**Non-Goals:**
- Multi-list `map` (e.g., `(map + '(1 2) '(3 4))`) — single-list `map` is sufficient for macros
- `for-each`, `filter`, `fold` — can be added later

## Decisions

**`map` as ECE function, not primitive**: `map` needs to call ECE procedures (the function argument). CL primitives can't invoke the evaluator's apply dispatch. Defining `map` in ECE using `define` and recursion is natural and works with closures, lambdas, and primitives alike.

**`apply` as special form**: `apply` is implemented as a special form with continuation handlers `ev-apply` and `ev-apply-did-proc` and `ev-apply-dispatch`. The handler evaluates the procedure and argument list expressions, then sets `argl` and `proc` and jumps to `:apply-dispatch`. This preserves TCO and `call/cc` semantics and handles both ECE procedures and primitives correctly. Add `apply` to `*special-forms*` and add `apply-form-p` predicate.

**Simple CL forwarding for `cadr`, `caddr`, etc.**: These are direct `#'cadr`, `#'caddr` symbol-function references — no wrapper needed.

**`pair?` maps to CL `consp`**: Scheme's `pair?` returns true for any cons cell, which is CL's `consp`.

## Risks / Trade-offs

- [`map` defined in ECE is slower than a CL primitive] → Acceptable for macro-time code; correctness matters more than speed here
- [`apply` as special form adds complexity] → Three continuation handlers, but this is the same pattern used by other special forms and is necessary for correctness
