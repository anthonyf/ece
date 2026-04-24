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

## P0.5 — Keywordize archive format

**Status:** roadmap bullet; spec to be written after P0 merges.

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

## P1 — CL rename `*executing-space-id*` → `*executing-code-obj*`

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

## Out of scope for this roadmap

- **Per-PC source-map in archive format** — diagnostics roadmap thread 5.
- **WASM codegen backend (compile-to-host Phase 2)** — browser-port roadmap item. Depends on P0 landing first (archive loader produces code-objects; codegen tool emits host-native dispatch per code-object).
- **Display closures / stack-based call frames (Dybvig §4.4, Ch 4)** — evaluator-design work, orthogonal to code-objects.

## Ordering

P0 → P0.5 → P1 → P2. All four shipped; see individual section headers
for status + artifacts.
