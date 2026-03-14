## Context

ECE's compiler (SICP 5.5) currently emits name-based variable lookup instructions: `(assign val (op lookup-variable-value) (const x) (reg env))`. At runtime, `lookup-variable-value` does an O(frames × vars-per-frame) linear scan, which profiling shows consumes **44% of total execution time**.

The compiler already tracks lexically-bound names in `*compile-lexical-env*` (a flat list for macro shadowing), so it knows at compile time whether a variable is lexically bound. SICP Exercises 5.41–5.43 describe extending the compiler to compute lexical addresses (depth, offset) and emit indexed access instructions.

### Current state

- Environment: linked list of frames, each frame is `(cons (var1 var2 ...) (val1 val2 ...))`
- Variable lookup: `lookup-variable-value` scans frame variables by name with `eq`
- `*compile-lexical-env*`: flat list of all lexically-bound names (used only for macro shadowing)
- Global frame: grows via `define-variable!` as new top-level definitions are added

## Goals / Non-Goals

**Goals:**
- Reduce variable lookup from 44% to near-zero for lexically-bound variables
- Maintain full backward compatibility for ECE programs (same semantics)
- Keep the global environment name-based (globals are not lexically addressable)

**Non-Goals:**
- Optimizing global variable lookup (separate future work — e.g., hash table for global frame)
- Changing the compiler architecture or instruction sequence format
- Inline caching or JIT compilation
- Optimizing `get-reg`/`set-reg`, instruction vector access, or other secondary bottlenecks

## Decisions

### 1. Compile-time lexical environment structure

**Decision**: Change `*compile-lexical-env*` from a flat list of names to a list of frames (each frame a list of names), mirroring runtime environment structure.

```
;; Current: flat list
*compile-lexical-env* = (x y z a b)

;; New: list of frames
*compile-lexical-env* = ((x y) (z) (a b))
```

**Why**: To compute `(depth . offset)`, the compiler needs to know which frame contains each variable and at what position. A flat list loses frame boundaries.

**Alternative considered**: Storing a hash table mapping names to (depth, offset). Rejected because frames are pushed/popped as scopes are entered/exited — a list of frames naturally handles this with simple `cons`/`cdr`.

### 2. Frame representation: vectors

**Decision**: Change runtime frames from parallel lists `(cons (var1 var2 ...) (val1 val2 ...))` to simple vectors `#(val1 val2 ...)`. The variable names are not stored in lexical frames at all — they are only needed at compile time.

**Why**: Vectors give O(1) indexed access via `svref`, making `lexical-ref` a true O(1) operation. Lists would require O(offset) traversal via `nth`.

**Exception**: The global frame retains the current list-based structure because global variables are looked up by name (the compiler can't predict runtime `define` positions).

**Alternative considered**: Keep list-based frames, use `nth` for offset access. Rejected because `nth` is O(n) and frames can have many bindings, reducing the benefit.

### 3. New runtime operations

**Decision**: Add two new operations to the register machine:

- `lexical-ref (depth offset env)` → value at position `(depth, offset)` in env
- `lexical-set! (depth offset val env)` → mutate position `(depth, offset)` in env

These traverse `depth` frames via `cdr`, then index into the vector at `offset`.

**Implementation**:
```lisp
(defun lexical-ref (depth offset env)
  (let ((frame (nth-frame depth env)))
    (svref frame offset)))

(defun lexical-set! (depth offset val env)
  (let ((frame (nth-frame depth env)))
    (setf (svref frame offset) val)))

(defun nth-frame (depth env)
  (loop repeat depth do (setf env (cdr env)))
  (car env))
```

### 4. Compiler variable resolution

**Decision**: `compile-variable` and `compile-assignment` check `*compile-lexical-env*` for a lexical address. If found, emit `lexical-ref`/`lexical-set!`. If not found (global/free variable), emit the existing `lookup-variable-value`/`set-variable-value!`.

```lisp
;; New helper
(defun find-variable (var env)
  "Return (depth . offset) if var is lexically bound, or nil."
  (loop for frame in env
        for depth from 0
        do (let ((offset (position var frame)))
             (when offset (return (cons depth offset))))))
```

**Emitted instructions**:
```
;; Lexical variable (depth=1, offset=2):
(assign val (op lexical-ref) (const 1) (const 2) (reg env))

;; Global variable (no lexical address):
(assign val (op lookup-variable-value) (const x) (reg env))
```

### 5. `extend-environment` changes

**Decision**: `extend-environment` produces vector frames for lambda calls and list frames for global definitions.

When called with a parameter list and argument list (from compiled lambda entry), it creates a vector frame:
```lisp
(defun extend-environment (vars vals base-env)
  ;; For lexical frames: build a vector from vals
  (cons (coerce-to-frame-vector vars vals) base-env))
```

The existing global `define-variable!` continues to work on the list-based global frame unchanged.

**Rest parameters**: For dotted parameter lists like `(a b . rest)`, the vector stores positional args at known offsets and the rest list at the final offset.

### 6. Image format compatibility

**Decision**: Accept a **breaking change** to the image format. Vector frames will be serialized using the existing `vec N` opcode in the flat image format. Old images with list-based frames cannot be loaded.

**Why**: The image is regenerated from source (`make image`). There is no deployed fleet of images that needs migration.

### 7. `define-variable!` in lexical scope

**Decision**: Internal `define` forms within lambda bodies are compiled as `set!` to a pre-allocated slot in the frame vector. The compiler knows all `define` names in a body (via `extract-define-names`, which already exists) and includes them in the frame.

This matches the existing behavior where `compile-lambda-body` already calls `extract-define-names` indirectly through `*compile-lexical-env*`.

**Implementation**: When compiling a lambda body, collect all internal `define` names, allocate frame slots for them (initialized to `undefined`), and compile the `define` forms as `lexical-set!` to those slots.

## Risks / Trade-offs

**[Risk] Internal defines ordering** → The compiler must scan the full body for `define` names before compiling any expressions in that body. This is already done by `extract-define-names` for macro shadowing, so no additional work is needed.

**[Risk] Debugging difficulty** → Lexical frames lose variable names, making runtime inspection harder. → Mitigation: Keep a compile-time mapping of (entry-pc → parameter names) in `*procedure-name-table*` or a new table. The REPL error handler can use this for debugging output.

**[Risk] Rest parameter handling** → Dotted parameter lists `(a b . rest)` must correctly place the rest argument at a known offset. → Mitigation: `flatten-params` already handles this; the rest parameter gets the last slot in the vector.

**[Risk] Serialization of vector frames** → `flat-image-serialize` must handle vectors in frame position. → Mitigation: The serializer already handles vectors via the `vec N` opcode. Frames are just vectors in environment position — no special case needed.

**[Risk] Global `define` at top level** → Top-level `define` forms must still use name-based `define-variable!` on the global frame. → Mitigation: The compiler checks `find-variable`; if it returns nil, the existing name-based code path is used unchanged.
