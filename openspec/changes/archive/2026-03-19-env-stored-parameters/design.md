## Context

ECE parameters (`make-parameter`, `parameterize`) currently use a CL-side hash table (`*parameter-table*`) to store values. The environment holds an opaque `(primitive PARAM3)` tag that dispatches through this table. This indirection was needed by the old image serializer but is now dead weight — the current ECE-side serializer can't see the CL table, so parameter values are silently lost during continuation serialization.

## Goals / Non-Goals

**Goals:**
- Parameters serializable by default (no special handling)
- Remove `*parameter-table*`, `*parameter-counter*` from CL kernel
- Remove `symbolp` special-case dispatch in `apply-primitive-procedure`
- All existing parameter/parameterize tests pass unchanged
- `parameterize` dynamic rebinding semantics preserved

**Non-Goals:**
- Changing `parameterize` macro implementation (it should work as-is)
- Thread-safe parameters (single-threaded ECE)
- Deep `parameterize` + continuation interaction (same semantics as before, just now serializable)

## Decisions

### 1. Parameter representation: `(parameter <cell>)` with mutable cell

**Choice:** A parameter is `(parameter (<value> . <converter-or-nil>))`. The inner cons cell is mutable — `set-car!` updates the value. The outer list is the tagged wrapper for type dispatch.

```
(make-parameter 42)       → (parameter (42 . nil))
(make-parameter "hi" fn)  → (parameter ("hi" . <fn>))
```

**Why:** The mutable cons cell lets `parameterize` save/restore values by mutating the same cell, preserving identity. The parameter object itself (the outer list) is stored in the environment and captured by closures. Multiple closures sharing the same parameter see the same cell — mutation is visible across all references. This matches the current `*parameter-table*` semantics exactly.

### 2. Executor dispatch: add `parameter?` branch

**Choice:** The executor's procedure call dispatch (in the compiled code's `test primitive-procedure? / test continuation?` sequence) gains a third check: `test parameter?`. The compiler emits this check for all procedure applications.

```
(test (op primitive-procedure?) (reg proc))
(branch (label primitive-branch))
(test (op continuation?) (reg proc))
(branch (label continuation-branch))
(test (op parameter?) (reg proc))        ;; NEW
(branch (label parameter-branch))        ;; NEW
;; compiled-procedure branch (default)
```

**Why:** Parameters need to be callable like procedures: `(p)` gets, `(p val)` sets. The executor must recognize them. Adding a branch to the dispatch is the same pattern used for primitives and continuations. The check is fast (`parameter?` is a list tag check).

### 3. CL-side helpers for parameter operations

**Choice:** Three CL functions added to the operations table:
- `make-parameter`: creates `(parameter (<value> . <converter>))`
- `parameter-ref`: `(car (cadr param))` — read the value
- `parameter-set!`: `(setf (car (cadr param)) new-val)` — mutate the value, return old

The converter application stays in the compiled code (the compiler generates inline code to check for and apply the converter).

**Why:** These are operations used in the executor's `(op ...)` instructions, not ECE-level functions. They need to be CL functions in the `get-operation` table for the executor to call them directly. The converter check is in compiled code because it involves a function call back into ECE (the converter might be a compiled procedure).

### 4. Compiler changes: parameter-branch in procedure call

**Choice:** `mc-compile-procedure-call` in compiler.scm adds a parameter branch to the dispatch sequence. The parameter branch:
- 0 args: `(assign val (op parameter-ref) (reg proc))`
- 1 arg: `(assign val (op parameter-set!) (reg proc) (reg argl))` (with converter check)
- 2 args: raw set (bypass converter, for `parameterize` restore)

**Why:** The compiler generates all procedure call dispatch code. Adding the parameter branch here means ALL calls to parameters go through the correct path. The arity dispatch (0/1/2 args) matches the current `apply-primitive-procedure` behavior.

### 5. `parameterize` macro: unchanged

**Choice:** The existing macro works as-is:
```scheme
(define-macro (parameterize bindings . body)
  `(let ((,old (,param)))       ;; calls param with 0 args → parameter-ref
     (,param ,val)              ;; calls param with 1 arg → parameter-set!
     (let ((,result ...body...))
       (,param ,old t)          ;; calls param with 2 args → raw set
       ,result)))
```

**Why:** The macro calls the parameter as a function with different arities. The executor's parameter-branch handles each arity. No macro changes needed.

### 6. Serialization: automatic via tagged list

**Choice:** The serializer recognizes `(parameter ...)` as a tagged type and emits `(%ser/parameter <value> <converter>)`. The deserializer reconstructs it.

**Why:** The serializer already handles tagged lists (`compiled-procedure`, `continuation`, `primitive`). Parameters are one more tag. No special sentinel or skip logic needed — parameter values ARE the data that should be serialized.

## Risks / Trade-offs

**[Executor hot path]** Adding a `parameter?` check to every procedure call adds one comparison to the common case (compiled procedures). Mitigation: parameters are rare in typical call sites. The check is a simple list-tag test. Compiled procedure calls are still the default fall-through.

**[Converter as compiled-procedure]** The converter function is a compiled procedure stored in the parameter cell. It's captured and serialized with the parameter. If the converter's code changes across rebuilds, the serialized converter breaks. Mitigation: same limitation as all serialized compiled procedures — this isn't new.
