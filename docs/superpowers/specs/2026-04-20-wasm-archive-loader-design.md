# WASM Archive Loader + `$comp-space` Retirement

**Date:** 2026-04-20
**Status:** Designed, ready for implementation plan
**Roadmap entry:** P0 in `2026-04-20-code-objects-completion-roadmap.md`

## Context

PR #163 flipped `bootstrap.ecec` to the `(ecec-archive version 2 ...)` format and retired `compilation-space` on the CL side. WASM's `$load_ecec_impl` still parses the legacy `(ecec-header (space name) ...)` format and still builds `$comp-space` structs; it traps with "illegal cast" when handed an archive. `test-wasm`, `test-web-server`, and `test-web-apps` are gated as `continue-on-error: true` in CI as a workaround.

This spec ports the archive parser to WAT, migrates the JS glue, retires the `$comp-space` infrastructure, and restores a single gating `make test` step in CI.

## Goals

1. WASM boots `bootstrap.ecec` (archive format) cleanly — no "illegal cast" traps, no dead legacy paths.
2. `make test-wasm`, `make test-web-server`, `make test-web-apps` all pass and become CI gates again.
3. WAT runtime has structural parity with the CL runtime: code-objects are the sole dispatch unit; no `$comp-space` residue.
4. JS glue surface matches the runtime model — no `space-id` parameter names that lie.

## Non-goals

- Per-PC source-map in the archive format (diagnostics roadmap thread 5).
- WASM codegen backend / native-fn attachment for archive-loaded code (browser-port Phase 2).
- Continuation serialization for code-objects (roadmap P2).
- CL rename `*executing-space-id*` → `*executing-code-obj*` (roadmap P1; separate PR).

## Design

### 1. Archive format recap

An archive is a single top-level s-expression:

```
(ecec-archive
  version 2
  file "<source-path>"
  entries (<entry> <entry> ...))
```

Each entry is:

```
(code-object
  name <symbol-or-#f>
  arity <integer-or-#f>
  source-loc <#f>            ; always #f post-§15.2 (archive carries file at wrapper level)
  labels ((<sym> . <pc>) ...)
  instructions (<instr-sexp> ...))
```

Entry 0 is the file's init code-object (top-level forms, including `set-macro!` calls for any macros). Entries 1..N-1 are nested lambdas hoisted from inside the init. Within `instructions`, references to other entries appear as `(co-ref <N>)` operands; the loader patches these to direct code-object pointers.

### 2. WAT loader: `$load-archive-impl`

New function replacing `$load_ecec_impl`. Signature:

```wat
(func $load-archive-impl (result (ref $code-object))
  ...)
```

**Algorithm:**

1. **Read archive:** `(local.set $archive (call $ecec-read-sexp))` — one call, one sexp.
2. **Version gate:**
   - Extract the head symbol of `$archive`. If it is `ecec-header`, trap with `"Legacy .ecec format no longer supported — run make bootstrap"`.
   - Extract the `version` field via `$archive-plist-get`. If not `= 2`, trap with `"Unsupported .ecec archive version: <N> — run make bootstrap"`.
3. **Pass 1 — skeleton:**
   - Extract `entries` via `$archive-plist-get`.
   - Count entries; allocate a WAT array of `(ref null $code-object)` sized to `N`.
   - For each entry at index `i`:
     - `$make-code-object` → struct shell.
     - Set `name`, `arity`, `source-loc` from entry fields (all may be `#f`).
     - Walk the `labels` alist; populate the code-object's label table.
     - Store in `cos[i]`.
4. **Pass 2 — instructions with co-ref patching:**
   - For each entry at index `i`, get `raw-instrs = entry.instructions`.
   - For each instruction sexp, call `$archive-patch-co-refs(sexp, cos)` which returns a new sexp with `(co-ref N)` subtrees replaced by direct `cos[N]` references.
   - Call `$ecec-parse-instr(patched-sexp, ...)` which returns a `$instr` with op-id already resolved. Push onto `cos[i].instructions`.
5. **Return:** `cos[0]` — the init code-object.

**Helper functions:**

- `$archive-plist-get(plist, key-symbol) → (ref null eq)` — walks a plist (`k1 v1 k2 v2 ...`), returns the value for the matching key or null. ~20 lines.
- `$archive-patch-co-refs(tree, cos-vec) → (ref null eq)` — recursive tree walker. If `(co-ref N)` is encountered, return `cos-vec[N]`; else recurse into `car`/`cdr` and cons back. ~30 lines.

**Complexity estimate:** ~150–200 lines total for `$load-archive-impl` + helpers. CL reference is 45 lines; WAT ratio is typically 3–4×.

**Trimmed vs legacy loader:**

- No `$create-space-internal` call.
- No `$ecec-register-macros` call — macros are regular code-objects in `entries`; init runs `set-macro!`.
- No `$register-source-map` call — per-PC source-map is a future, separate design.
- No section/cursor machinery — archive is one sexp per file.

### 3. Exports

**New:**

- `(export "load_archive")` — signature `(offset i32) (len i32) → (co_handle i32)`. Sets up the ecec read cursor to `[offset, offset+len)`, calls `$load-archive-impl`, allocates a handle wrapping the returned code-object.
- `(export "run_code_object")` — signature `(co_handle i32) (env_handle i32) → (result_handle i32)`. Calls `$execute` with `$init-code-obj = deref(co_handle)` and `$init-env = deref(env_handle)`, wraps the result via `$alloc-handle`.

**Retired (deleted from runtime.wat and glue.js):**

- `load_ecec`
- `load_ecec_continue`
- `ecec_has_more`
- `run` (the comp-space-based entry point)

### 4. JS glue (`wasm/glue.js`)

**New:**

- `loadArchiveText(text)` — mirrors the existing `loadEcecText` linear-memory write loop but calls `w.load_archive(0, text.length)` and returns a `co_handle`.
- `ECE.runCodeObject(co_handle)` — calls `w.run_code_object(co_handle, ECE.globalEnvHandle)`, returns the result handle.

**Replaced:**

- The one bootstrap call site at `glue.js:444` (currently `ECE.loadEcecBundleText(text)`) becomes `const co = ECE.loadArchiveText(text); ECE.runCodeObject(co);`.

**Deleted:**

- `loadEcecText`
- `loadEcecBundleText`

**External callers:** grep during implementation for `loadEcec` and `w.run(` across `ece-webapps`, `test-web-server`, `test-web-apps`, REPL harnesses, and any `*.html` in `webapps/`. Update each to the new names.

### 5. `$comp-space` retirement

After the new loader is in place and `make test-wasm` passes, delete:

**Types and globals:**
- `$comp-space` struct type (line 1441)
- `$space-array` type (line 1463)
- Global `$space-registry` backing storage

**Functions:**
- `$register-space`, `$get-space`, `$create-space-internal`
- `$space-set-instr`, `$space-set-labels`

**`$execute` shrink:**
- Drop `$init-space-id` and `$init-pc` params — only `$init-code-obj` and `$init-env` remain.
- Delete the `(ref.is_null $init-code-obj)` guard and the legacy comp-space branch it protects.
- Delete local `$space (ref null $comp-space)`.
- Rename local `$space-id i32` → delete (no longer needed; dispatch reads fields off `$co`).
- Rename local `$current-code-obj` → `$co` (tighter; aligns with CL's `code-obj`).
- Cross-procedure jumps write `$co` directly.

**Primitives:** delete trap/stub branches for IDs **125–135** (`%space-*` set) and **112**. Confirm the exact list during implementation by grepping `(i32.eq (local.get $id) (i32.const <N>))` and removing those that only trap.

**Source-map infrastructure:**
- `$register-source-map` and any per-space source-map hash tables.
- Source-map fields on `$comp-space` (moot after the struct is deleted).
- JS glue `ECE.sourceMap*` accessors if any exist.

The source-map *concept* returns in diagnostics roadmap thread 5, designed from scratch for the archive format. Retiring the legacy plumbing now prevents two half-working paths from confusing that design.

### 6. Error handling

- **Legacy header encountered:** trap at version-gate with `"Legacy .ecec format no longer supported — run make bootstrap"`. Fail loud.
- **Version mismatch:** trap with `"Unsupported .ecec archive version: <N> — run make bootstrap"`.
- **Malformed archive (missing `entries`, non-list, etc.):** reuse the `$ecec-read-sexp` error path — it already traps on read failures with file position info.
- **`(co-ref N)` with `N ≥ cos.length`:** trap with `"Archive co-ref out of range: <N>"`. Indicates a compiler bug, not a runtime recovery case.

## Testing

### Unit-level
No WAT-level test harness exists in the repo; we do not introduce one for this work. Coverage is at the integration level.

### Integration (existing suites)
- `make test-wasm` — full self-hosted ECE test suite running on the WASM runtime. Primary gate. Passing proves archive loader, code-object executor path, and comp-space retirement hang together.
- `make test-web-server` — Node/headless harness exercising `loadArchiveText` via JS glue.
- `make test-web-apps` — browser harness for `ece-webapps`.

### Local smoke
Before each commit: `make ece && make test-wasm` from the worktree. If red, iterate without burning CI minutes. This discipline was what made PR #163's Phase D zone-dispatch bug tractable — name-collision + float-truncation were only debuggable because each phase was verified in isolation.

### CI
Collapse the split step in `.github/workflows/test.yml` (lines 92–107) back to the original single-step form documented in the TODO comment at line 81:

```yaml
- name: Run all tests
  run: make test
```

Delete:
- `- name: Run non-WASM test suites`
- `- name: Run WASM-dependent tests (allowed to fail — known follow-up)`

## Implementation Ordering

Six commits, each individually green on `make test-wasm` locally:

1. Add `$load-archive-impl` + `$archive-plist-get` + `$archive-patch-co-refs`; add `load_archive` / `run_code_object` exports. Legacy paths still present; scratch harness validates the new path.
2. JS glue switchover: add `loadArchiveText` and `runCodeObject`; bootstrap path uses them. Run `make test-wasm`.
3. Delete legacy exports: `load_ecec`, `load_ecec_continue`, `ecec_has_more`, `run`. Delete `loadEcecText`, `loadEcecBundleText`. Update any external callers.
4. Retire `$comp-space`: delete struct, registry, `$register-space`, `$get-space`, `$create-space-internal`, `$space-set-*`. Shrink `$execute` signature. Rename locals.
5. Retire trapped `%space-*` primitive IDs (125–135, 112). Delete source-map infrastructure.
6. Restore `make test` single-step form in `.github/workflows/test.yml`; delete the TODO comment at line 81.

The roadmap doc lands as a separate commit at the start of the PR so it's reviewable standalone.

## Risks

- **Stray `$space-id` reference in executor fast path** — silently breaks everything. Mitigation: after the rename, full `make test-wasm` run will either fail WAT compilation or trap at runtime. The `bootstrap.ecec` boot path exercises the fast path heavily.
- **External JS caller unlisted in grep** — `ece-webapps` has enough call sites that one could be missed. Mitigation: full `make test-web-apps` run before PR.
- **Primitive ID retirement off-by-one** — IDs 112 and 125–135 are the likely set based on PR #163 notes but not authoritatively confirmed. Mitigation: implementation phase greps traps systematically, confirms each before deletion.

## References

- CL reference implementation: `src/runtime.lisp:1605` (`parse-archive-sexp`), `1584` (`archive-plist-get`), `1592` (`archive-patch-co-refs`), `1996` (`load-archive` driver)
- ECE-side equivalents: `src/compilation-unit.scm` (`archive-sexp->code-objects`, `archive/plist-get`)
- Current WAT legacy loader: `wasm/runtime.wat:6456` (`$load_ecec_impl`)
- Current executor with dual-path: `wasm/runtime.wat:2188` (`$execute`)
- JS glue to update: `wasm/glue.js:290–340`, `:444`
- CI workflow to restore: `.github/workflows/test.yml:81–107`
- Predecessor change: `openspec/changes/archive/2026-04-19-per-procedure-code-objects/`
- Memory tracker (obsoleted by this spec): `~/.claude/projects/-Users-anthonyfairchild-git-ece/memory/project_wasm_archive_loader_followup.md`
