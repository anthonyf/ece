## Why

Stage 1 (PR #141) shipped the inline codegen and dual-zone runtime with the assembler space as the sole compiled zone. CI already runs ~50% faster because every `(load ...)` call routes through native CL tagbody code instead of the interpreter dispatch loop. Expanding coverage to all seven bootstrap spaces would put the entire boot image — prelude, compiler, reader, syntax-rules, boot-env, compilation-unit, and assembler — in the compiled zone, maximising the performance benefit and proving the codegen handles every instruction pattern the compiler produces before Stage 2 (porting execute-instructions to ECE) builds on it.

The blocker discovered during the spike: SBCL's compiler stack-overflows on tagbody forms with more than ~5000 tags. Five of the seven spaces exceed this limit. The fix — sub-function splitting — is a codegen-only change that partitions a large zone into multiple CL functions of bounded size, with a lightweight dispatcher routing PCs to the right chunk. This is also a prerequisite for Stage 3's WASM backend, which has analogous function-size validation limits.

## What Changes

- **MODIFIED** `src/codegen-cl-inline.scm` — add sub-function splitting: when a space's instruction count exceeds a threshold (~4096 PCs), the codegen emits N chunk functions plus a dispatcher that routes initial-pc to the correct chunk. Each chunk is a self-contained tagbody with at most CHUNK-SIZE tags. Chunks return `(values pc val env proc argl continue stack)` when execution leaves their PC range or hits halt; the dispatcher loops until halt or zone-exit.
- **MODIFIED** `src/codegen-cl-inline.scm` — add single-session batch entry point `(generate-all-zones! output-dir)` that walks `*space-registry*` and generates one zone file per space in a single SBCL session, eliminating the per-space boot overhead.
- **NEW** `bootstrap/<space>-zone.lisp` for each of: `boot-env`, `compilation-unit`, `reader`, `syntax-rules`, `compiler`, `prelude` (six new generated files, checked in alongside the existing `assembler-zone.lisp`).
- **MODIFIED** `Makefile` — replace the single `assembler-zone.lisp` rule with a batch rule that generates all zone files in one SBCL invocation. Wire into `make bootstrap` with correct dependency ordering (zone files depend on `bootstrap.ecec`).

## Capabilities

### New Capabilities

- `compiled-zone-splitting`: Sub-function splitting for compiled zones whose instruction count exceeds SBCL's single-tagbody compilation limit. The codegen partitions the space into bounded-size chunks, each emitted as a separate CL function with its own tagbody, and generates a dispatcher that routes PCs to the correct chunk.

### Modified Capabilities

- `inline-primitive-codegen`: The existing per-space codegen gains sub-function splitting for large spaces and a batch generation entry point. The single-space `generate-zone-cl!` entry point continues to work unchanged; the new `generate-all-zones!` is additive.

## Impact

- **Affected code**: `src/codegen-cl-inline.scm` (sub-function splitting + batch entry point), `Makefile` (batch rule), `bootstrap/` (six new generated files totalling ~375k lines).
- **Build time**: Single-session batch codegen for all 7 spaces: ~120s codegen + ~30s boot = ~2.5 min. SBCL compilation of zone files at first boot: ~90s total (cached in `.fasl-cache/` thereafter).
- **Runtime behavior**: All bootstrap spaces dispatch through compiled zones. The interpreter loop is only reached for REPL-entered code, dynamically-loaded files, and register-valued gotos that bail from a compiled zone. Observable semantics are unchanged — the parity test harness from PR #141 covers call/cc, dynamic-wind, REPL redefinition, and continuation serialization.
- **No API changes**: `*compiled-zone-functions*`, the zone calling convention, and `execute-instructions`' dual-zone hook are all unchanged from PR #141.
- **Rollback**: Delete `bootstrap/<space>-zone.lisp` for any space. The runtime falls through to the interpreter for that space without code changes.
