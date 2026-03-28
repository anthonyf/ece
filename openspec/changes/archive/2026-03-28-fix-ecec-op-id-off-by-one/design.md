## Context

The WASM runtime has two functions that resolve operation name symbols to numeric op-ids:

- **`$resolve-op-name`** (line 1253): Used by the runtime assembler. Scans asm-sym-ids slots 17–39 inclusive (`i32.gt_u ... 39`). Correctly finds all 23 ops (0–22).
- **`$ecec-op-id`** (line 5085): Used by the ecec text loader's `$ecec-parse-operand`. Scans slots 17–38 (`i32.ge_u ... 39`). Misses slot 39, so `do-continuation-winds` (op 22) resolves to -1.

The ecec text loader calls `$ecec-parse-operand` → `$ecec-op-id` when parsing `(op <name>)` operands in assign, test, and perform instructions. The -1 is stored as the `c` field of the instruction struct, which the validator rejects (c must be 0–22).

## Goals / Non-Goals

**Goals:**
- Fix `$ecec-op-id` to scan the same range as `$resolve-op-name`
- All 5 space validation failures pass after the fix

**Non-Goals:**
- Unifying `$ecec-op-id` and `$resolve-op-name` into one function (deferred — they serve different callers but the duplication is noted)
- Changing the executor or compiler

## Decisions

**Fix the scan bound, not merge the functions.** `$ecec-op-id` returns -1 for unknown ops (used defensively) while `$resolve-op-name` returns 0 (defaults to `lookup-variable-value`). Merging them would change error behavior. The minimal fix is changing the loop bound.

## Risks / Trade-offs

- **[Low] Two functions with same purpose but different defaults.** `$ecec-op-id` returns -1, `$resolve-op-name` returns 0. If a future op is added at slot 40+, both bounds need updating. Consider a shared implementation later.
