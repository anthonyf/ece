# Code-Objects Completion Roadmap

**Date:** 2026-04-20
**Status:** Active
**Predecessor:** `openspec/changes/archive/2026-04-19-per-procedure-code-objects/` (PR #163, merged)

## Context

PR #163 (`per-procedure-code-objects`) retired `compilation-space` on the CL side: the `compilation-space` struct, `*space-registry*`, `%space-*` primitives, and `(symbol . pc)` qualified-address closures are gone. Code objects are the sole dispatch unit in the CL runtime. WASM got code-object *primitives* (ids 241–257) and a code-object-aware executor branch, but the bootstrap loader and the comp-space infrastructure on WASM did not migrate.

Three items remain before "code-objects" is fully done on both hosts.

## P0 — WASM archive loader + `$comp-space` retirement

**Status:** designed. See `2026-04-20-wasm-archive-loader-design.md`.

Port `parse-archive-sexp` to WAT, migrate JS glue to `loadArchiveText` / `runCodeObject`, retire `$comp-space` / `$register-space` / `$get-space` / the legacy executor branch, delete trapped `%space-*` primitive IDs, restore `make test` as the CI single-step gate. Structural parity with the CL side.

**Why P0:** unblocks `test-wasm`, `test-web-server`, `test-web-apps` from CI `continue-on-error`; removes the longest-lived dead-code path in the codebase.

## P1 — CL rename `*executing-space-id*` → `*executing-code-obj*`

**Scope (CL side):**
- `src/runtime.lisp` — rename the defvar (line 1226), the binding in `$execute` equivalent (line 1242), and the cross-procedure assignment (line 1283). Rename references in `capture-continuation` paths (lines 987, 1086).
- `src/codegen-cl-inline.scm` — three string/symbol references (lines 736, 741, 926).
- `src/primitives.scm` — comment only (line 25).
- `openspec/specs/instruction-executor/spec.md` — update the spec wording.

**Why:** the defvar holds a code-object post-PR-#163; the name is a lie. Straight mechanical rename, no behavior change. Risk is low but non-zero because the name appears in inline-codegen templates — if any string reference is missed, the generated zone code won't compile.

**Why separate PR:** unrelated to WASM work; bundling adds noise to the WASM review. Best done after P0 merges so the rename diff is reviewable on its own.

**Estimate:** one sitting. Brainstorm → plan → execute in a single session, no subagent decomposition needed.

## P2 — Continuation serialization for code-objects

**Current state:** `src/prelude.scm:1202` emits `(%ser/opaque-co)` as a placeholder for code-object operands in captured continuations. Deserialization rebuilds closures pointing at an `opaque-co` space that doesn't exist. Three tests in `test-serialization.scm` are commented out under a `TODO(per-procedure-code-objects §G1)` marker.

**Why P2 and not P1:** this is a semantics decision, not mechanical cleanup. Two broad approaches will surface in its own brainstorm:

1. **Serialize by reference** — `(%ser/co-ref <archive-file-stem> <index>)`. Deserialization looks up the registered archive in `*archive-code-objects*`. Cheap, small payload. Fails if the source archive is missing at deserialize time.
2. **Serialize inline** — emit the full instruction vector + labels + metadata inside the continuation blob. Self-contained. Heavier payload (continuations blow up in size) and re-introduces the archive-inlining problem the archive format was designed to avoid.

A hybrid is likely: reference by default, inline for anonymous / REPL-compiled code. Needs its own brainstorm because the choice interacts with save-game / save-world UX.

**Why P2 and not deferred indefinitely:** call/cc serialization is a shipped feature (PR #163's §G1 "done" column notwithstanding). The `%ser/opaque-co` placeholder is a known-broken escape hatch, not a feature. Users calling `save-continuation!` on a CL-side continuation today will silently get an un-invokable closure back.

**Prerequisite:** P0 merged. With WASM code-object infra in place, any serialization format designed here will work on both hosts.

## Out of scope for this roadmap

- **Per-PC source-map in archive format** — diagnostics roadmap thread 5.
- **WASM codegen backend (compile-to-host Phase 2)** — browser-port roadmap item. Depends on P0 landing first (archive loader produces code-objects; codegen tool emits host-native dispatch per code-object).
- **Display closures / stack-based call frames (Dybvig §4.4, Ch 4)** — evaluator-design work, orthogonal to code-objects.

## Ordering

P0 first. P1 anytime after P0 merges. P2 needs its own brainstorm before design; no hard blocker after P1 but pairing them in the same quarter keeps the code-object model in working memory.
