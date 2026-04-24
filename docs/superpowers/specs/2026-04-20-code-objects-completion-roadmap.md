# Code-Objects Completion Roadmap

**Date:** 2026-04-20
**Status:** Active
**Predecessor:** `openspec/changes/archive/2026-04-19-per-procedure-code-objects/` (PR #163, merged)

## Context

PR #163 (`per-procedure-code-objects`) retired `compilation-space` on the CL side: the `compilation-space` struct, `*space-registry*`, `%space-*` primitives, and `(symbol . pc)` qualified-address closures are gone. Code objects are the sole dispatch unit in the CL runtime. WASM got code-object *primitives* (ids 241–257) and a code-object-aware executor branch, but the bootstrap loader and the comp-space infrastructure on WASM did not migrate.

Four numbered items (P0 / P0.5 / P1 / P2) were identified to finish "code-objects" on both hosts. All four have shipped. Three smaller loose ends surfaced during implementation; they're documented under "Known follow-ups" below.

## P0 — WASM archive loader + `$comp-space` retirement — **Shipped**

**Status:** Shipped via PRs #164 + #165. Design: `2026-04-20-wasm-archive-loader-design.md`.

Port `parse-archive-sexp` to WAT, migrate JS glue to `loadArchiveText` / `runCodeObject`, retire `$comp-space` / `$register-space` / `$get-space` / the legacy executor branch, delete trapped `%space-*` primitive IDs, restore `make test` as the CI single-step gate. Structural parity with the CL side.

**Why P0:** unblocks `test-wasm`, `test-web-server`, `test-web-apps` from CI `continue-on-error`; removes the longest-lived dead-code path in the codebase.

## P0.5 — Keywordize archive format — **Shipped**

**Status:** Shipped via PR #168.

**Scope:** flip the archive shape from plain symbols to `:keyword` tags:

- Wrapper head: `(ecec-archive ...)` → `(:ecec-archive ...)`
- Plist tags: `version file entries` → `:version :file :entries`
- Entry head: `(code-object ...)` → `(:code-object ...)`
- Entry fields: `name arity source-loc labels instructions` → `:name :arity :source-loc :labels :instructions`

Matches idiomatic Scheme and makes named parameters read as named parameters.

**Blocker:** the `.ecec` keyword round-trip bug (`~/.claude/projects/-Users-anthonyfairchild-git-ece/memory/project_ecec_keyword_roundtrip_bug.md`). `write-to-string-flat` escapes `:foo` as `|:foo|`; CL's `read` then interns into the `:keyword` package instead of `:ece`; `archive-plist-get`'s `eq?` lookup silently fails.

**Coordinated fix required in a single bootstrap cycle:**
- `ece-print-flat` in `src/runtime.lisp` — emit `:foo` bare (no pipes) for `:ece`-package symbols whose name starts with `:`.
- `downcase-ece-symbols` in `src/runtime.lisp` — normalize CL keywords back to `:ece`-package symbols named `":foo"`.
- WAT reader side — verify `:foo` tokens intern into the same symbol the ECE reader produces; fix `$ecec-read-sexp` if not.
- Regenerate `bootstrap.ecec` and all zone files.

**Why P0.5 and not bundled with P0:** a prior attempt cascaded — the symbol name dropped its colon somewhere, producing mismatched round-trips. Needs focused debugging on a stable baseline. Bundling into the WASM port would block CI gate recovery on an orthogonal runtime bug; a red `make bootstrap` during the keyword fix would leave the WASM branch unbootable mid-PR.

**Why P0.5 and not deferred indefinitely:** the archive format is young enough that flipping once is cheap; flipping after years of accumulated `.ecec` files in the wild is expensive. Doing it now, between P0 and P1, costs one bootstrap regen.

## P1 — CL rename `*executing-space-id*` → `*executing-code-obj*` — **Shipped**

**Status:** Shipped via PR #166.

**Scope (CL side):**
- `src/runtime.lisp` — rename the defvar (line 1226), the binding in `$execute` equivalent (line 1242), and the cross-procedure assignment (line 1283). Rename references in `capture-continuation` paths (lines 987, 1086).
- `src/codegen-cl-inline.scm` — three string/symbol references (lines 736, 741, 926).
- `src/primitives.scm` — comment only (line 25).
- `openspec/specs/instruction-executor/spec.md` — update the spec wording.

**Why:** the defvar holds a code-object post-PR-#163; the name is a lie. Straight mechanical rename, no behavior change. Risk is low but non-zero because the name appears in inline-codegen templates — if any string reference is missed, the generated zone code won't compile.

**Why separate PR:** unrelated to WASM work; bundling adds noise to the WASM review. Best done after P0 merges so the rename diff is reviewable on its own.

**Estimate:** one sitting. Brainstorm → plan → execute in a single session, no subagent decomposition needed.

## P2 — Continuation serialization for code-objects — **Shipped**

**Status:** Landed on branch `codeobj-serialization`. Design:
`docs/superpowers/specs/2026-04-22-codeobj-serialization-design.md`.
Plan: `docs/superpowers/plans/2026-04-22-codeobj-serialization.md`.

**What shipped:**

- Hybrid dispatch: archive-registered code-objects serialize as
  `(%ser/co-ref <stem> <index>)`; anonymous/REPL-compiled code-objects
  serialize as `(%ser/co-inline :name ... :instructions ...)`.
- O(1) dispatch via a new `archive-key` field on the `code-object`
  struct (CL defstruct + WAT struct), populated by
  `register-archive-code-objects` (CL) and `archive-sexp->code-objects`
  (ECE). WASM archive loader leaves it null — inline fallback is the
  documented degradation until the WASM loader ports the stem parser.
- Deserialization via `deser/lookup-archive-co` (by-reference) and
  `deser/reconstruct-co-inline` (inline); nested code-objects in
  instruction operands resolve recursively through
  `deser/walk-instruction`.
- Typed error `ece-deser-missing-archive-error` raised when a by-
  reference lookup hits an unregistered stem — callers can `guard` on
  the specific class and prompt the user to load the archive.
- New primitives: 258 `code-object-archive-key`, 259
  `%code-object-set-archive-key!`, 260 `%archive-co-lookup`.
- Re-enabled the four `TODO(per-procedure-code-objects §G1)` tests in
  `tests/ece/cl-only/test-serialization.scm`. Added one new UX test
  for the typed-error path. Test count: 1305 → 1319 passed.
- Removed the `%ser/opaque-co` placeholder — both serializer and
  deserializer. Only archived proposals and this roadmap doc retain
  historical references.

## Known follow-ups

Code-object-related loose ends surfaced during P0/P2 implementation but not covered by the four numbered items above. Not currently blocking anything; documented here so they're tracked in one place.

- **Three disabled WASM yield tests.** `yield single frame`, `yield multi-frame (3 cycles)`, and `handle table stable over 100 yield cycles` in `wasm/test.js` are commented out; see the `TODO (archive-loader follow-up)` at `wasm/test.js:55`. Disabled during P0 because they depended on the source-map infrastructure retired alongside `$comp-space`. Re-enable requires either a smaller regression test that exercises `do-continuation-winds` through the code-object path without yield-loop specifics, or fixing the underlying `do-continuation-winds` + code-object interaction so the original assertions hold. The op 19 handler in `wasm/runtime.wat:2711` carries the matching `TODO (archive-loader follow-up)` marker.

- **`CRASH: Unknown expression type -- MC-COMPILE: #?` diagnostic from the WASM test harness.** Seen locally during `make test-wasm` runs across this session; `wasm/test.js` does exit non-zero on `eceCrash` (see line 224), so if this actually fires in CI the suite should fail — the behavior on this machine's merged-main may reflect a stale local state that CI doesn't hit. Worth reproducing cleanly before diagnosing. Note that `MC-COMPILE` errors format via `write-to-string` of the offending expression, so the literal `#?` in the message is likely the writer's fallback for an unprintable value (not a reader literal the user wrote), meaning the real bug is upstream of the compile call — whatever expression reached `mc-compile` was already malformed.

- **WASM archive-key population.** P2's hybrid serializer relies on an `archive-key` field on each code-object to dispatch between `(%ser/co-ref …)` and `(%ser/co-inline …)`. The CL archive loader populates the field during `register-archive-code-objects`; the WASM archive loader does not (documented as a TODO in `wasm/runtime.wat` at primitive 260). Consequence: code-objects loaded on WASM always serialize inline, inflating continuation-blob sizes and preventing cross-host `(%ser/co-ref …)` round-trips — a CL save-game with by-reference entries can't be deserialized on WASM even if the same archive is loaded there. Fully closing this requires the WASM loader to parse the archive's `:file` wrapper and stamp `(stem . index)` onto each code-object as it's constructed, mirroring what `register-archive-code-objects` does on CL.

## Out of scope for this roadmap

- **Per-PC source-map in archive format** — diagnostics roadmap thread 5.
- **WASM codegen backend (compile-to-host Phase 2)** — browser-port roadmap item. Depends on P0 landing first (archive loader produces code-objects; codegen tool emits host-native dispatch per code-object).
- **Display closures / stack-based call frames (Dybvig §4.4, Ch 4)** — evaluator-design work, orthogonal to code-objects.

## Ordering

P0 → P0.5 → P1 → P2. All four shipped; see individual section headers
for status + artifacts.
