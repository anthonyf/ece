## Context

ECE primitives are stored in the environment as `(primitive #<FUNCTION>)`. When `call/cc` captures a continuation, the stack may contain saved `proc` values with these opaque function objects, making continuations non-serializable. This refactor replaces function objects with their CL symbol names.

## Goals / Non-Goals

**Goals:**
- All primitive procedure objects store a symbol instead of a function object
- `:primitive-apply` resolves symbol → function at call time
- Zero behavior change — all existing tests pass
- After this change, everything on the stack/continuation is a pure s-expression

**Non-Goals:**
- Adding serialization primitives (future work)
- Changing how closures or macros are stored (already s-expressions)

## Decisions

### Primitive alist change
Currently:
```lisp
(list 'primitive (symbol-function (if (listp proc) (cdr proc) proc)))
```
Change to:
```lisp
(list 'primitive (if (listp proc) (cdr proc) proc))
```
This stores the CL symbol (e.g., `+`, `null`, `characterp`) instead of the function object.

### Dolist registration change
Currently:
```lisp
(cons 'read (list 'primitive #'ece-read))
```
Change to:
```lisp
(cons 'read (list 'primitive 'ece-read))
```

### Apply dispatch change
Currently:
```lisp
(setf val (apply (cadr proc) (nreverse argl)))
```
Change to:
```lisp
(setf val (apply (symbol-function (cadr proc)) (nreverse argl)))
```
One `symbol-function` lookup per primitive call. This is a hash table lookup in SBCL — negligible cost.

## Risks / Trade-offs

- **Micro performance**: One extra symbol lookup per primitive call. `symbol-function` is O(1) in all major CL implementations. Unmeasurable in practice.
- **No risk to correctness**: `(symbol-function 'foo)` returns exactly the same function object that `#'foo` would. The only difference is when the lookup happens (call time vs load time).
