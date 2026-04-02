## Context

The `load_ecec` function in `wasm/runtime.wat` uses a two-pass architecture:
- **Phase 1**: Read all compilation units from the `.ecec` text, accumulate them in a `$units` list, and count total instructions in `$pc`.
- **Phase 2**: Iterate `$units`, create instruction structs, and store them in the compilation space.

Currently, `create-space-internal` is called *before* Phase 1 with a hard-coded capacity of 65,536. The `$pc` count from Phase 1 is available but unused for sizing. This means any `.ecec` file with more than 65K instructions triggers an out-of-bounds array trap during Phase 2's `$space-set-instr` calls.

## Goals / Non-Goals

**Goals:**
- Remove the hard-coded 65,536 instruction limit from `load_ecec`
- Size compilation spaces to the exact instruction count determined by Phase 1
- Re-enable `test-wasm` in the CI test suite

**Non-Goals:**
- Changing the `.ecec` file format
- Modifying the `$create-space-internal` function signature
- Adding dynamic array resizing (exact sizing is sufficient)

## Decisions

**Move space creation between Phase 1 and Phase 2.** After Phase 1 completes, `$pc` holds the exact instruction count. Pass `$pc` (or `$pc` + small padding) to `$create-space-internal` instead of 65,536. This requires no changes to the Phase 1 or Phase 2 logic — only relocating one function call and changing its capacity argument.

**No space-name dependency issue.** The space name is extracted from the `.ecec` header *before* Phase 1, so it's available at the new call site between phases.

## Risks / Trade-offs

- **Over-allocation**: The previous 65K fixed allocation over-provisioned small files. Dynamic sizing allocates exactly what's needed — more memory-efficient for small files, correctly sized for large ones.
- **No risk of under-counting**: Phase 1 counts instructions with the same `$ecec-is-instr-keyword` predicate that Phase 2 uses, plus accounts for inter-unit `env-reset` instructions. The count is exact.
