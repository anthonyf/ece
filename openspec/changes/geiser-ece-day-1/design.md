## Context

ECE's current inner-loop is `bin/ece-repl`, which runs `src/ece-main.scm`'s `(repl)` function: `read`, `try-eval`, `write`, loop. That's fine at a terminal for a handful of expressions but doesn't integrate with emacs, which is the primary developer's editor. Every mature Scheme implementation ships a **Geiser** backend that lets emacs drive the REPL: `C-x C-e` to eval at point, `C-c C-l` to load file, REPL buffer hosted via `comint-mode`, output + errors displayed inline.

Geiser's architecture is split in two:

```
 ┌────────────────────┐              ┌────────────────────┐
 │      EMACS         │              │  SCHEME RUNTIME    │
 │                    │              │                    │
 │  geiser-mode.el    │              │  (implementation   │
 │  (generic UI:      │              │   registers        │
 │   REPL buffer,     │              │   geiser:eval,     │
 │   key bindings,    │              │   geiser:load-     │
 │   minibuffer       │              │   file, etc.       │
 │   display)         │              │   Support code     │
 │                    │              │   loaded at        │
 │  geiser-ece.el  ◀──┼── protocol ──┼─▶  startup)        │
 │  (impl adapter:    │              │                    │
 │   spawn, prompt    │              │                    │
 │   regex, request   │              │                    │
 │   formatting)      │              │                    │
 └────────────────────┘              └────────────────────┘
         ▲                                    ▲
    M-x run-geiser,                     `bin/ece-repl --geiser`
    C-x C-e, C-c C-l                    spawned by comint
```

Each Geiser implementation provides a ~few-hundred-line elisp file that tells generic Geiser how to talk to *that* Scheme, plus a Scheme-side support file that's loaded at startup and defines the `geiser:*` request handlers. The request-response format is S-expressions over stdio — no sockets, no JSON, no protobuf, just `(geiser:eval #f (+ 1 2))` going in and `((result "3") (output "") (error #f))` coming out. This matches ECE's existing REPL transport (stdin/stdout) exactly.

The current REPL has one memory-tracked pitfall that matters for day 1: error recovery can leave stale labels in the bootstrap compilation space, so subsequent expressions hit "Unknown label" errors. With a bare terminal REPL the user just restarts it; with Geiser driving `load-file` in a batch, the first erroring form poisons every later form in the same file. Not acceptable.

## Goals / Non-Goals

**Goals:**

- Stock Geiser backend: emacs users running Geiser see `ece` as a selectable implementation, pick it, and get a working REPL buffer.
- Minimum viable handlers: `geiser:eval`, `geiser:load-file`, `geiser:version`, `geiser:no-values`. Anything Geiser requests beyond these returns a graceful "not supported in day 1" response.
- `C-x C-e` works end-to-end: user positions point after a form in a `.scm` buffer, evaluates it, sees the result in the minibuffer and echoed in the REPL buffer.
- `C-c C-l` loads the whole current buffer.
- Error display: when eval raises, emacs shows the error message (not a raw backtrace dump) and the REPL remains usable for subsequent forms.
- Solid CL-side automated test coverage so regressions in the wire protocol are caught without depending on emacs manual checks.
- Error-recovery fix bundled if it's localised; extracted to a prereq PR if it turns out to touch the assembler or executor.

**Non-Goals:**

- Completions (`geiser:completions`) — no Scheme-side introspection helper for global-env enumeration yet; deferred to day 2.
- Autodoc / arglist hints (`geiser:autodoc`) — needs compiled-procedure signature extraction; deferred.
- Jump-to-definition (`geiser:symbol-location`) — depends on source-location tracking (debugging roadmap thread 5).
- Symbol documentation (`geiser:symbol-documentation`) — ECE has no formal docstring convention yet.
- Macro expansion (`geiser:macroexpand`) — needs `*compile-time-macros*` exposure; deferred.
- Module browser, inspector, debugger, tracing — all phase 2+.
- WASM runtime as host — phase 2+; day 1 is CL host only.
- Browser integration — phase 2+; not in this change's scope at all.
- `ece serve` integration ("REPL is the game" mode) — phase 2+.
- Melpa release / ELPA packaging — phase 2+.

## Decisions

### Decision 1: Stock Geiser backend over custom emacs mode

**Choice:** Implement as a Geiser backend (elisp file registering ECE with `geiser-impl`), not a bespoke `ece-mode.el`.

**Rationale:** Geiser already provides the REPL buffer, comint wiring, key bindings, minibuffer display, prompt detection, and output formatting. A custom emacs mode would reinvent all of that. Every feature added to a custom mode would also need to be tested and documented. A Geiser backend is mostly *declarative* — we register metadata and a handful of command handlers, and Geiser's generic UI takes care of the rest. The incremental cost of a custom mode would grow with every feature added in phases 2+; the Geiser backend inherits those features for free.

**Alternatives considered:**

- **Custom `ece-mode.el`** — more freedom, no Geiser dependency, smaller initial elisp footprint. Rejected because the freedom isn't worth it for day 1, and every later phase would have more work to do.
- **SLIME-ish custom protocol** — structured, rich, would support the inspector and debugger cleanly later. Rejected as over-engineered for day 1; Geiser's simple stdio protocol gets us to working `C-x C-e` in a fraction of the time.

### Decision 2: CL host only for day 1

**Choice:** `bin/ece-repl --geiser` is the CL-side entry point. The WASM runtime is not a day 1 target.

**Rationale:** The CL runtime is the faster-booting, full-featured host with real debuggers, matching the reference implementation role noted in `feedback_no_cl_abandonment.md`. Adding WASM runtime support would double the test surface and introduce transport issues (stdin/stdout of a Node host driving the WASM interpreter) that have nothing to do with the actual Geiser backend contract. Day 2+ can add a `ece-repl-wasm --geiser` transport without changing the wire protocol or the handler shapes.

**Alternatives considered:**

- **WASM-first** — would force the protocol to be host-agnostic from day 1, which is good. Rejected because the user is already productive on the CL host and the urgency is emacs integration, not WASM coverage.
- **Dual-host day 1** — twice the test surface, twice the chance of a regression, for no practical gain in day 1 user experience.

### Decision 3: Structured wire protocol via in-band alist sentinel

**Choice:** The `--geiser` REPL mode prints responses as `((result "...") (output "...") (error #f))` on a line prefixed with a recognizable sentinel marker (exact string TBD during implementation — probably something like `;;geiser-response: ` or a zero-width ASCII prefix). The prompt `ece> ` is unchanged.

**Rationale:** Geiser backends almost universally use in-band stdio responses; SLIME's socket-based protocol is explicitly *not* the Geiser model. Keeping it in-band means no new transport layer, no sockets, no port allocation, no firewall rules. The elisp side just scans comint output for the sentinel. An explicit prefix disambiguates structured responses from free-form output that the eval'd code itself writes.

**Alternatives considered:**

- **Out-of-band socket protocol** — richer, supports async notifications, but doubles the transport complexity and requires a port allocation dance. Rejected.
- **JSON envelope** — industry standard, but ECE already has an alist JSON encoder (`src/json.scm`) we could reuse. Geiser's own convention is S-expressions, and reading an S-expression on the elisp side is trivial (`(read (current-buffer))`), so JSON adds no value.
- **No prefix, rely on line shape** — fragile, especially if eval'd code prints something that looks like an alist. Rejected.

### Decision 4: Error recovery fix — bundle if ≤50 lines, else prereq PR

**Choice:** Investigate the "stale labels in bootstrap space" pitfall during implementation. If the fix is a localised change to `compile-and-go` (or a new `compile-and-go-throwaway` variant that allocates a fresh space per REPL input), bundle it. If it requires changes to the assembler or executor, extract to a prereq PR named `fix-repl-error-recovery` and cite it in the commit message of this change.

**Rationale:** Day 1 utility depends on the fix — `C-c C-l` batch-sending a file with any syntax error in its middle will poison every later form. But the user also explicitly said "if you can bundle" — not "you must bundle" — so large/invasive fixes get their own change. The investigation is mandatory; the bundling is contingent.

**Alternatives considered:**

- **Ship day 1 without the fix and document the limitation** — rejected because it makes the feature immediately frustrating the first time a user `C-c C-l`s a mid-edit file.
- **Fix first in a separate PR regardless** — would delay the Geiser day-1 ship by the time it takes to PR, review, and merge the error-recovery fix. Only worth it if the fix is invasive.

### Decision 5: `bin/ece-repl --geiser` flag, not a new binary

**Choice:** Add a `--geiser` flag to `bin/ece-repl`, not a separate `bin/ece-repl-geiser` symlink.

**Rationale:** `bin/ece-repl` is already a thin dispatch wrapper. Adding a boolean flag is trivial — a new symlink means yet another argv[0] branch in `ece-main.scm`, a Makefile line, an install target update, a .gitignore entry, and a documentation note. For a single-boolean selector, the flag is the right grain.

**Alternatives considered:**

- **`bin/ece-repl-geiser` symlink** — cleaner URL, slightly more discoverable. Rejected as over-weight for a boolean.
- **Environment variable `ECE_REPL_GEISER=1`** — rejected as less discoverable than a flag.

### Decision 6: File locations

**Choice:**
- Elisp file at `emacs/geiser-ece.el` (new `emacs/` directory at repo root).
- Scheme support at `src/geiser-ece.scm` (alongside the other SDK files).
- Tests at `tests/ece/cl-only/test-geiser-ece.scm` (CL-only because they spawn subprocesses) and Rove tests in `tests/ece.lisp`.

**Rationale:** The `emacs/` directory is new, which is intentional — it flags that the file is not a build artifact but a companion that users load from their emacs init. Phase 2 could promote it to `emacs/geiser-ece/geiser-ece.el` (an ELPA-ish layout) or leave it flat. `src/geiser-ece.scm` follows the same convention as `src/ece-serve.scm`, `src/ece-build.scm`, etc. CL-only tests match the existing `test-source-locations.scm` pattern.

**Alternatives considered:**

- **`contrib/emacs/`** — common convention for external integrations, but ECE doesn't have a contrib/ directory and inventing one for one file is premature.
- **Keep elisp inline as a docstring** — rejected; emacs users expect a file to `load`.

## Risks / Trade-offs

- **[Risk] Wire protocol format may diverge from real Geiser convention.** The sentinel-prefixed alist is my best guess at the shape; real Geiser backends likely use a slightly different format.
  **Mitigation:** Read one or two small existing Geiser backends (chibi or chicken) during implementation to ground the exact format. If the actual format is different, change the sentinel string before the PR merges. The fallback is simple: the CL-side tests specify the format and the elisp side parses what the CL side emits, so even an ad-hoc format works as long as it's consistent.

- **[Risk] Error recovery fix balloons beyond 50 lines.** If cleaning up the bootstrap space requires reworking how `compile-and-go` allocates instruction vectors or threads label tables through the executor, the fix could become a multi-day project.
  **Mitigation:** Time-box the investigation to one day. If after a day it's not tractable, extract to prereq PR `fix-repl-error-recovery`. Document the investigation findings (even if no code lands in this change) in a memory file so the prereq PR has context.

- **[Risk] Output capture interacts badly with ECE's existing `%yield!` / animation-frame machinery or with parameterize / dynamic-wind.** If a user evaluates a form that yields mid-execution, does the captured output stream unwind correctly?
  **Mitigation:** Day 1's target is the CL-host REPL, which has no `%yield!` interaction. The CL REPL is synchronous end-to-end. Edge cases around yield are out of scope until WASM host day arrives.

- **[Risk] `try-eval` currently catches CL-level `error` broadly.** If a primitive raises a stream error (per PR #157's investigation), `try-eval` may or may not catch it correctly, and the error message format may not be what Geiser expects.
  **Mitigation:** The tests verify the response shape on error. If `try-eval` loses error context we want to show in emacs, either tighten it in this change or document the gap and schedule a follow-up.

- **[Trade-off] Day-1 scope is deliberately tiny.** Completions, autodoc, jump-to-def, macroexpand are all classic Geiser features, and shipping without them means the first user experience is "eval works, nothing else does."
  **Mitigation:** This is deliberate and matches the user's stated priority ("start small with just the CL host only"). The proposal enumerates phase 2+ and makes clear which features land when. The day-1 UX is "your editor can eval ECE code without a terminal" — a meaningful jump over the status quo even without completions.

## Migration Plan

- **Forward:** merge this change. Users install `emacs/geiser-ece.el` via `(load "path/to/geiser-ece.el")` in their init.el. `M-x run-geiser` now offers `ece` as a selectable implementation.
- **Rollback:** revert the single implementation PR. `bin/ece-repl` returns to pre-PR behavior (the `--geiser` flag is opt-in; omitting it is byte-identical). Users who installed `emacs/geiser-ece.el` in their init see an error on next emacs restart; removing the `load` line restores their emacs. No data migration, no state, no binary compatibility concerns.
- **Version gate:** none needed — day 1 is additive and opt-in.

## Open Questions

- **What exact format does Geiser expect for eval responses?** Answerable during implementation by reading a small existing Geiser backend. Current assumption is an alist; reality may be slightly different.
- **Does Geiser need a `(module)` concept from day 1?** ECE's `.ecec` compilation spaces map loosely to modules, but there's no user-visible module namespace. Assumption: pass `#f` or ignore, and Geiser's module-insensitive code path handles it. Verify during implementation.
- **Does the error-recovery fix belong in this change?** Answerable after a half-day investigation of `compile-and-go` and how bootstrap-space labels are allocated on compilation failure.
- **How should the `bin/ece-repl --geiser` output capture interact with writes to `*error-output*`?** Probably redirect both `current-output-port` and `current-error-port` into the same capture and tag with `(output ...)`. Verify during implementation.
