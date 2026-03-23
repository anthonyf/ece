## Context

The drop-ececb change made `$instr.$c` and `$instr.$val` mutable to support a post-creation label resolution pass. This broke WasmGC nominal type dispatch — `ref.test (ref $continuation)` returns false for valid `$continuation` structs when the containing code was loaded from WAT-reader-parsed `.ecec` files. Runtime-compiled identical code works correctly.

The fix: eliminate the need for mutable `$instr` fields by resolving all labels before creating any instructions.

## Goals / Non-Goals

**Goals:**
- Restore `$instr.$c` and `$instr.$val` to immutable
- Fix game loop yield/resume (game loop, sierpinski, analog clock demos)
- Remove `$cont-tag` workaround from `$continuation` type

**Non-Goals:**
- Changing how `yield` or `call/cc` work
- Changing the sandbox's `call_ece_proc`-based resume mechanism

## Decisions

### 1. Two-phase label resolution in `load_ecec`

The current single-pass approach creates instructions immediately and mutates their fields during a second resolution pass. The new approach splits into two phases:

**Phase 1 — Collect:** Read all units as s-expressions, store them in a list. While scanning each unit, record all labels with their PCs in a global labels alist. Count instruction PCs (skip labels).

**Phase 2 — Build:** Iterate the stored unit list. For each non-label item, create the instruction with labels already resolved using the complete labels alist.

Key difference from the earlier failed attempt: store the parsed unit s-expressions in a list (not cursor positions) so phase 2 can iterate them without re-parsing. The labels alist accumulates across ALL units before ANY instructions are created.

### 2. Updated function signatures

- `$ecec-parse-instr(sexp, space-id, pc, labels)` — takes labels alist, resolves label references during `struct.new $instr`
- `$ecec-build-operand-list(ops, labels)` — resolves label operands (type 2) to `(2 . fixnum(pc))` immediately
- Remove `$ecec-resolve-labels` and `$ecec-resolve-operand-labels` — no longer needed

### 3. Instruction creation with resolved labels

For instructions that reference labels:

| Instruction | Field `$c` | Field `$val` |
|---|---|---|
| branch | `ecec-label-pc(label-sym, labels)` | `$nil` |
| goto-label | `ecec-label-pc(label-sym, labels)` | `$nil` |
| assign-label | `ecec-label-pc(label-sym, labels)` | `$nil` |
| assign-op/test/perform | unchanged | operand list with labels resolved |

### 4. Remove `$cont-tag` from `$continuation`

With `$instr` fields immutable, binaryen generates the same type layout as before the drop-ececb change. The `$continuation` type no longer needs the tag field to prevent type deduplication.

## Risks / Trade-offs

- **Memory:** Phase 1 stores all unit s-expressions in a list. For prelude (~87 units), this is a temporary allocation of ~87 cons cells pointing to the already-parsed unit lists. Negligible.
- **Correctness:** The earlier two-phase attempt had a bug (null pointer during prelude loading). The new design explicitly stores units in a reversed list and reverses it before phase 2, ensuring correct order. The `$ecec-parse-instr` must be updated to accept the `labels` parameter and resolve all label types inline.
