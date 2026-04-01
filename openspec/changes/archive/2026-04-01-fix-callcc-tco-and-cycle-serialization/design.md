## Context

ECE's compiler (SICP 5.5) compiles Scheme to register machine instructions executed by a `tagbody/go` loop. `call/cc` is compiled by `mc-compile-callcc` (compiler.scm:498-527), which captures the current stack and continue register as a continuation object, then dispatches to a receiver procedure.

The serializer (`serialize-value` / `deserialize-value` in prelude.scm:830-1111) handles shared structure via a two-pass `%ser/def`/`%ser/ref` mechanism: Pass 1 counts object occurrences by identity, Pass 2 emits definition/reference tags for multiply-referenced objects.

Two bugs exist:

1. `mc-compile-callcc` always installs a local `return-label` trampoline — even in tail position. This causes `end-with-linkage 'return` to wrap the sequence with `save continue` / `restore continue`. When the receiver tail-calls out, the restore is never reached, leaking one stack entry per iteration.

2. `deserialize-value` stores ref-table entries for `%ser/def` *after* recursing into the body (prelude.scm:1046-1050). Cyclic structures (e.g., a letrec closure referencing its own frame) hit a `%ser/ref` before the entry exists.

## Goals / Non-Goals

**Goals:**
- Tail-position `call/cc` produces O(1) stack growth, matching the TCO guarantee of all other tail forms
- Cyclic object graphs (letrec, recursive define) survive serialization round-trips
- Existing non-tail `call/cc` behavior is unchanged
- Existing non-cyclic serialization behavior is unchanged

**Non-Goals:**
- Optimizing continuation size beyond fixing the leak (e.g., stack compaction)
- Supporting serialization of arbitrary CL objects or opaque host types
- Changing the serialization wire format (the `%ser/def`/`%ser/ref` tag scheme stays)

## Decisions

### 1. Tail-position call/cc: mirror `mc-compile-proc-appl` pattern

**Decision**: Add a conditional branch in `mc-compile-callcc` that checks `(eq? linkage 'return)`. When true, emit code that:
- Captures the continuation using the caller's `continue` directly (no local return-label)
- Dispatches to the receiver as a true tail call (reusing the caller's `continue`)

**Rationale**: This is exactly how `mc-compile-proc-appl` (compiler.scm:322-326) handles tail calls — the `(eq? target 'val) (eq? linkage 'return)` case just does `goto (reg val)` without setting `continue` to a local label. The call/cc case needs the same treatment, with the addition of `capture-continuation` before dispatch.

**Alternative considered**: Modifying `end-with-linkage` or `preserving` to detect the call/cc pattern and suppress the save. Rejected — too fragile, and the explicit two-path approach is clearer and matches SICP style.

### 2. Tail-position call/cc: three-way dispatch

**Decision**: The tail-position code path needs the same three-way dispatch (compiled / continuation / primitive) as the non-tail path, but with tail-call linkage for each branch:
- **Compiled receiver**: `goto (reg val)` with `continue` unchanged (true tail call)
- **Primitive receiver**: `assign val = apply-primitive-procedure(proc, argl)`, then `goto (reg continue)` (primitives return immediately, then we tail-return)
- **Continuation receiver**: restore stack/continue from the continuation object and `goto (reg continue)` (same as non-tail — invoking a continuation is always a non-local jump)

**Rationale**: All three cases already exist in the non-tail path. The tail variants just skip the return-label indirection.

### 3. Cycle deserialization: pre-allocate-and-patch for pairs

**Decision**: When `deser` encounters a `%ser/def` whose body is a pair (the most common cycle carrier), pre-allocate a `(cons #f #f)` placeholder, store it in the ref-table immediately, then recursively deserialize the car and cdr, and patch them into the placeholder via `set-car!`/`set-cdr!`.

**Rationale**: Cycles in ECE's object graph pass through pairs — specifically the environment list `(frame . outer-env)`. The cycle is: env-frame (in a vector slot) → closure → env (a pair) → car is the frame → which contains the closure. The pair is always the link that closes the cycle. Pre-allocating the pair and registering it before recursing means `%ser/ref` finds it during body deserialization.

**Alternative considered**: Pre-allocating all compound types (vectors, env-frames). More complex and not needed — the cycle always passes through a cons cell (the env chain). Vectors and env-frames don't self-reference directly; they reference through the pair-based env list.

### 4. Cycle deserialization: detect pair bodies by tag inspection

**Decision**: In the `%ser/def` handler, peek at the body form's tag. If it's a non-tagged pair (or a recognized compound tag like `%ser/env-frame`, `%ser/vector`), use the pre-allocate-and-patch path. For atoms and simple tagged forms, use the existing direct path.

Actually, simpler: since any `%ser/def` body that participates in a cycle must be a compound type, and pre-allocating a cons cell only costs one extra cons when there's no cycle, we can **always** pre-allocate for pair bodies. For other compound types, the straightforward approach is:

- **Pairs**: pre-allocate `(cons #f #f)`, patch after
- **Vectors**: pre-allocate `(make-vector n #f)`, fill slots after
- **Env-frames**: pre-allocate `(%make-env-frame #f #f '())`, patch after

But given that cycles always flow through pairs (the env chain), we only strictly need the pair case. We can add vector/env-frame pre-allocation later if needed.

**Decision refined**: Pre-allocate-and-patch for `%ser/def` bodies that are pairs. Direct deser for everything else. This minimizes the change while fixing the actual bug.

### 5. No changes to serialization output format

**Decision**: The serialization pass (Pass 1 scan + Pass 2 emit) is unchanged. Only deserialization is modified.

**Rationale**: The serializer already correctly handles cycles — it stops recursing on revisit in Pass 1, and emits `%ser/ref` on revisit in Pass 2. The bug is solely in deserialization's ordering of ref-table population.

## Risks / Trade-offs

**[Risk] Tail-position call/cc changes compiled instruction layout** → Requires `make bootstrap` (two-pass) since compiler.scm compiles to .ecec. Standard procedure for compiler changes; well-tested workflow.

**[Risk] Pre-allocate-and-patch changes pair identity** → The deserialized pair is the pre-allocated cons cell, not a fresh one from `deser-pair`. This is correct — the ref-table points to it, so all `%ser/ref` references resolve to the same object. No identity change for non-cyclic pairs (they don't go through `%ser/def`).

**[Trade-off] Only pairs get pre-allocation, not all compound types** → If a cycle exists that doesn't pass through a pair (hard to construct in ECE but theoretically possible via a vector that directly contains itself), it would still fail. Acceptable: ECE's environment structure always uses pairs as the cycle link. Can be extended later.

**[Risk] Mutation primitives required** → `set-car!` and `set-cdr!` are already available in ECE. `vector-set!` and `%env-frame-set-*!` exist if we extend to those types later.
