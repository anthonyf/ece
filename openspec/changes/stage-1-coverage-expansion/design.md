## Context

PR #141 shipped the inline codegen (`src/codegen-cl-inline.scm`) and the dual-zone runtime hook in `execute-instructions`. PR #142 fixed three SBCL compilation limits (bucketed case dispatch, hash-set label lookup, fixnum pc declaration). The assembler space (962 instructions) is the only compiled zone today.

A spike attempted to compile all seven bootstrap spaces. Codegen succeeded for all of them (total ~120s in a single session after the hash-set fix), but SBCL's compiler stack-overflows on tagbody forms with more than ~5000 tags. Five spaces exceed this: compilation-unit (7267), reader (11307), syntax-rules (12221), compiler (19612), prelude (43910). Boot-env (5262) is right at the edge and loads today but is fragile.

The infrastructure that already works:
- `generate-zone-cl!` produces correct CL for all seven spaces
- The bucketed entry-dispatch handles arbitrarily many PCs
- The `fixnum` pc declaration prevents type-inference blowups
- The runtime hook, parity tests, and self-registration all work unchanged

The only missing piece is sub-function splitting to keep each CL function's tagbody under SBCL's ~4096-tag limit.

## Goals / Non-Goals

**Goals:**

- Compile all seven bootstrap spaces (assembler, boot-env, compilation-unit, reader, syntax-rules, compiler, prelude) to compiled zones.
- Implement sub-function splitting so the codegen handles spaces of any size.
- Add a batch entry point `(generate-all-zones! output-dir)` that generates all zone files in a single SBCL session.
- Replace the per-space Makefile rule with a single batch rule, cutting build time from N separate SBCL boots to one.
- All four test suites (rove, ECE self-hosted, conformance, WASM) pass with all zones loaded.

**Non-Goals:**

- Performance benchmarking or optimization beyond what the compiled zones naturally provide. Stage 1's criterion is correctness parity, not measured speedup.
- Compiling the browser-lib space (it's skipped during CL boot and has no instructions in the CL image).
- Changing the zone calling convention, the runtime hook, or the parity test harness from PR #141.
- Per-procedure compilation granularity. Sub-function splitting is per-PC-range, not per-ECE-procedure.

## Decisions

### 1. Chunk size: 4096 PCs per sub-function

**Choice**: Each chunk function handles at most 4096 consecutive PCs. A space with N instructions produces ceil(N/4096) chunk functions plus one dispatcher.

**Rationale**: SBCL's compiler overflows at ~5000 tags. 4096 gives comfortable headroom (the bucketed entry dispatch adds ~16 cond branches per chunk, well within limits). Powers of two make the dispatcher's range checks clean (`(< pc 4096)`, `(< pc 8192)`, ...).

**Alternatives considered**:
- 2048 — more chunks, more cross-chunk overhead. Rejected: 4096 works and halves the chunk count.
- 8192 — too close to SBCL's limit given the entry dispatch adds overhead. Rejected.
- Adaptive (measure and split) — overengineered for Stage 1. Rejected.

### 2. Chunk function shape

**Choice**: Each chunk is a standalone `(defun zone-NAME-chunk-K ...)` with the same 7-in/7-out calling convention as the top-level zone function. The dispatcher is the top-level `(defun zone-NAME ...)` which loops: pick the right chunk based on pc, call it, check if it halted (pc >= total count) or needs another chunk.

**Rationale**: Reuses the existing calling convention. Each chunk is independently compilable. The dispatcher is trivial — a cond over pc ranges calling the matching chunk. When a chunk's internal goto lands outside its range, it returns the updated register state and the dispatcher routes to the next chunk.

**Alternatives considered**:
- Single function with multiple tagbodies — CL doesn't allow `(go)` between separate tagbody forms. Rejected.
- Closures sharing mutable state — more complex, no benefit. Rejected.
- One top-level tagbody with chunk helper functions called from it — the top-level tagbody would still need all the tags. Rejected: defeats the purpose.

### 3. Cross-chunk control flow

**Choice**: When a chunk's goto or branch targets a PC outside its [start, end) range, it sets pc to the target and returns `(values pc val env proc argl continue stack)`. The dispatcher sees pc is in a different range and calls the right chunk. For halt, the chunk sets pc past the total instruction count and returns — the dispatcher exits.

Register-valued gotos (`(goto (reg continue))`) bail to the dispatcher the same way they bail to zone-exit today — no change in semantics.

**Rationale**: The dispatcher loop adds one function call per cross-chunk transition. Intra-chunk gotos remain direct `(go pc-N)` with zero overhead. Cross-chunk transitions are rare relative to intra-chunk ones (most gotos target nearby PCs within the same procedure body).

### 4. Batch generation in a single session

**Choice**: `(generate-all-zones! output-dir)` iterates over the bootstrap spaces, calling `generate-zone-cl!` for each, all within one SBCL session.

**Rationale**: Each SBCL boot takes ~30s (loading ASDF, the runtime, the .ecec files). Seven separate boots = 3.5 min of pure overhead. One boot + seven codegen calls = ~30s overhead + ~120s codegen = ~2.5 min total.

### 5. Small spaces (< chunk-size) emit unchanged

**Choice**: Spaces with fewer than CHUNK-SIZE instructions emit a single `(defun zone-NAME ...)` with no dispatcher or chunk wrapper — identical to the current output.

**Rationale**: The assembler (962 PCs) and boot-env (5262 PCs if under threshold) don't need splitting. Keeping the simple path avoids unnecessary indirection and preserves byte-identical output for already-shipped zone files when the threshold is above their PC count.

## Risks / Trade-offs

- **[SBCL version sensitivity]** The ~5000-tag limit is empirical on SBCL 2.6.3/macOS-arm64. Other SBCL versions or platforms may have different limits. Mitigation: 4096 threshold gives ~20% headroom. If a CI platform hits it at 4096, lower to 2048.

- **[Cross-chunk overhead]** Each cross-chunk transition is a function call+return (register state copy via multiple-values). For spaces where hot loops span chunk boundaries, this adds overhead. Mitigation: 4096 PCs per chunk is large enough that most procedure bodies fit within one chunk. Performance is a non-goal for Stage 1.

- **[Generated file size]** The prelude zone will be ~165k lines. All seven zones total ~375k lines of checked-in CL. Mitigation: the files are auto-generated and clearly marked. Git handles them fine. `.gitattributes` can mark them as generated for diff suppression if desired.

- **[Build time]** ~2.5 min for a full zone regeneration. Mitigation: zone files only regenerate when their dependencies change (Makefile rules). Day-to-day development rarely touches all source files simultaneously.

- **[First-boot FASL compilation]** SBCL compiles each zone .lisp to .fasl on first load (~90s total). Mitigation: cached in `.fasl-cache/` thereafter. Only paid on clean builds or after zone regeneration.

## Open Questions

- **Should we add `*.zone.lisp linguist-generated` to `.gitattributes`?** Would suppress diffs in GitHub PRs. Likely yes.
- **Should the batch entry point skip browser-lib automatically?** It has 0 instructions in the CL image. Probably filter on instruction count > 0.
