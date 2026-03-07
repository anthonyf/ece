## Context

ECE uses CL's reader, which already parses `#(1 2 3)` as CL vectors. CL vectors support all the operations Scheme needs. The main design question is how to handle `vector-set!` since it's a mutation operation on a data structure (not a variable binding like `set!`).

## Goals / Non-Goals

**Goals:**
- Vectors as a first-class self-evaluating data type
- Full set of R7RS-style vector primitives
- Mutable vector elements via `vector-set!`

**Non-Goals:**
- Immutable vectors or vector freezing
- Growable/resizable vectors
- Multi-dimensional arrays

## Decisions

### Self-evaluation
Add `vectorp` to `self-evaluating-p`. CL vectors are already distinct from lists, so this is a one-line change. `#(1 2 3)` will evaluate to itself.

### Primitive mappings
- `vector?` → `vectorp` (direct)
- `vector-length` → `length` (CL's `length` works on vectors)
- `vector-ref` → `aref` (direct — same arg order as Scheme)
- `make-vector` → wrapper: `(make-array n :initial-element fill)` with optional fill defaulting to 0
- `vector` → wrapper: `(apply #'vector args)` — CL's `vector` function constructs from args
- `vector-set!` → wrapper: `(setf (aref vec idx) val)` returns val
- `vector->list` → `coerce` wrapper: `(coerce vec 'list)`
- `list->vector` → `coerce` wrapper: `(coerce lst 'vector)`

### vector-set! as a primitive
`vector-set!` can be a regular primitive because it mutates the vector object itself (via `setf aref`), not a variable binding. The vector is passed by reference (it's a CL object), so mutation through the primitive function is visible to the caller. No special form needed.

## Risks / Trade-offs

- **CL vector literals are not adjustable**: `#(1 2 3)` creates a simple vector. `vector-set!` works on simple vectors, so this is fine.
- **make-vector fill argument**: Scheme's `make-vector` has optional fill. Our wrapper will default to 0 if not provided, matching common Scheme behavior.
