## Context

The WAT `.ecec` reader builds instructions by parsing s-expressions from linear memory. The old binary loader built instructions by parsing a binary format from JS. Both should produce identical `$instr` structs for the same `.ecec` file. The binary loader worked correctly (yield, serialize-value, all demos). The WAT reader has subtle bugs.

The `ecec-op-id` off-by-one (scanning slots 17-37 instead of 17-38) was one such bug. After fixing it, yield works but serialize-value still crashes. The crash occurs in prelude-compiled code — the same code works when compiled at runtime.

## Goals / Non-Goals

**Goals:**
- Find ALL val field differences between WAT reader and binary loader
- Fix each difference at its root cause in the WAT reader
- Add a regression test that catches future differences
- Unblock save/load (PR #39)

**Non-Goals:**
- Rewriting the WAT reader from scratch
- Adding the binary loader back permanently (just for comparison)

## Decisions

### 1. Comparison approach

Extract the old binary loader (`parseBinary` + `loadParsed`) from git history (commit d316763) into a standalone comparison script. This script:

1. Loads a `.ecec` file via the binary loader (using the old `.ececb` of the same file)
2. Loads the same `.ecec` file via the WAT reader
3. For each instruction PC, compares the `$val` field using `write_val` (string representation)
4. Reports the first N differences with instruction details

The binary loader was removed in the drop-ececb PR but the `.ececb` files exist in git history. For comparison, we just need the prelude — it's the file where both yield and serialize-value live.

### 2. Comparison script structure

A standalone Node.js script `wasm/compare-loaders.js`:
- Extracts `parseBinary` and `loadParsed` from git (or inlines them)
- Creates two WASM instances: one loads prelude via binary, one via WAT
- Iterates all ~27,000 instruction PCs
- For each: calls `dbg_instr(sid, pc, 4)` on both, calls `write_val` on both handles, compares strings
- Prints differences with full instruction context

### 3. Investigation process

1. Run the comparison script — get a list of all differing PCs
2. For each difference, identify the pattern (what kind of instruction, what kind of val)
3. Group differences by root cause (likely a single WAT reader bug produces many differences)
4. Fix each root cause in the WAT reader
5. Re-run comparison until zero differences
6. Verify yield and serialize-value work

### 4. Known candidates for bugs

- **CL-ism handling**: The `.ecec` file has CL-printed values (`NIL`, `T`, `#S(SCHEME-FALSE)`). The `$ecec-check-special` function handles these, but might miss edge cases in nested contexts.
- **Constant values**: `(const ...)` values in operand lists might be parsed differently than top-level constants.
- **Dotted pair parsing**: The `$ecec-read-list` function handles dotted pairs. If a constant contains a dotted pair, parsing might differ.
- **String escaping**: Strings with escape sequences (`\n`, `\t`, `\"`) might parse differently.
- **Negative numbers**: The reader handles leading `-` for negative numbers. Edge cases with `-0` or negative in nested contexts.
- **procedure-name metadata**: The `procedure-name` items are skipped but might affect PC counting.

### 5. Regression test

After fixing, add to `wasm/test.js`:
- A val-field comparison for a representative subset of instructions (e.g., every 100th instruction)
- Or: a hash/checksum of all val field representations, compared against a known-good value

## Risks / Trade-offs

- **Comparison depends on old binary loader**: The binary loader code is in git history. We inline it in the comparison script, not in production code.
- **String comparison of vals**: Two structurally identical values might print differently (e.g., symbol ordering in hash tables). Use `write_val` which produces Scheme-readable output — should be deterministic.
- **Multiple root causes**: The comparison might reveal many differences from multiple bugs. Fix them one at a time.
