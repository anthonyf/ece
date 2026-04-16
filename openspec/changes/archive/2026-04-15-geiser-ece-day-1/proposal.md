## Why

The primary developer is a long-time emacs user, and ECE's current inner-loop is "type directly at the bare `ece> ` terminal REPL" — fine for a two-line experiment, miserable for a real editing session. Every other serious Scheme implementation (Racket, Chez, Guile, Chicken, MIT, Chibi, Gambit) ships a **Geiser** backend so emacs becomes the edit surface and the Scheme process becomes a subordinate — you edit `.scm` files in emacs, `C-x C-e` a form to evaluate it, `C-c C-l` loads the whole file, and a REPL buffer captures output. ECE needs to be on that list.

Day 1 of this is deliberately small: get a **stock Geiser backend** working against the **CL host only** with solid automated coverage of the CL-side wire protocol. Browser integration, WASM host, completions, jump-to-def, autodoc, macroexpand, and the inspector all come later. The point of day 1 is that the user can open an ECE source file in emacs, `M-x run-geiser`, pick `ece`, and immediately eval forms without touching the terminal.

A known REPL pitfall (from `project_wasm_fixnum_range.md`-adjacent memory and the `Known Pitfalls` section of CLAUDE.md) becomes critical the moment Geiser is driving the REPL: **error recovery can leave stale labels in the bootstrap space, causing "Unknown label" errors on the next expression.** Single-expression eval works fine today, but Geiser's `load-file` sends a whole file in one batch, and the first form that errors poisons every subsequent form. This change either bundles the fix or, if the fix turns out to be larger than expected, explicitly punts it to a prereq PR so day 1 isn't immediately broken.

## What Changes

- **ADDED** `emacs/geiser-ece.el` — a stock Geiser backend, written as an elisp file that registers ECE as a Geiser implementation via `geiser-impl:define` (or the equivalent `geiser-implementation-help` API, depending on Geiser version). Wires comint to `bin/ece-repl --geiser`, sets the prompt regexp, provides `geiser-ece--geiser-procedure` to format eval / load-file / no-values / version requests as Scheme forms the backend process parses, and ships enough `scheme-mode` + `paredit-mode` defaults so the buffer feels right on open. Initial package metadata is inline; no melpa release yet, the file is loaded via `(load "path/to/geiser-ece.el")`.
- **ADDED** `src/geiser-ece.scm` — Scheme-side support for the wire protocol. Provides:
  - `(geiser:eval module expr)` — evaluates `expr`, captures anything written to `current-output-port`, catches errors, returns a structured alist response `((result "42") (output "") (error #f))` (or `(error "message")` on failure). `module` is ignored in day 1 — ECE doesn't expose spaces as emacs-level modules yet, and Geiser accepts `#f` / ignored-module backends.
  - `(geiser:load-file path)` — wraps ECE's existing `load`, captures output, catches errors, returns the same structured alist.
  - `(geiser:version)` — returns ECE's version string.
  - `(geiser:no-values)` — returns Geiser's no-values marker.
  - Internal: `%geiser-with-output-capture thunk` — installs a fresh string-output-port as `current-output-port` for the duration of `thunk` and returns `(values thunk-result captured-output-string)`.
- **ADDED** `--geiser` flag on `bin/ece-repl`. When set, the REPL runs in structured-output mode: instead of `(write result) (newline)`, it emits the alist response wrapped in a recognizable sentinel (e.g., `;; geiser-response: ((result "...") (output "...") (error #f))`) that the elisp side scans for. The prompt is unchanged (`ece> `) so the elisp prompt regex is minimal.
- **MAYBE-ADDED** REPL error-recovery fix. Current `try-eval` wraps `evaluate` in a CL `handler-case`, but compilation failures in the bootstrap compilation space can leave stale labels behind. Investigation: determine whether `compile-and-go` can be given a throwaway space per call, so a compilation failure discards the entire space rather than polluting the bootstrap space's label table. If that turns out to be ~50 lines and localised, bundle it. If it requires cross-cutting changes to the assembler / executor, **extract it to a prereq PR** (`fix-repl-error-recovery`) and land that first. Either way, day 1 is useless without it by the time `C-c C-l` becomes a habit.
- **ADDED** tests in `tests/ece/cl-only/test-geiser-ece.scm` + Rove tests in `tests/ece.lisp` that:
  - Call `geiser:eval` directly with simple expressions and verify the response shape.
  - Call `geiser:eval` with an error-raising expression and verify the handler returns `(error "...")` without crashing the REPL state.
  - Call `geiser:load-file` on a small fixture file under `.tmp/` and verify the response.
  - Spawn `bin/ece-repl --geiser` as a subprocess, feed it requests via stdin, read responses, and verify end-to-end wire behavior. Uses `sb-ext:run-program` (CL-only, Rove-side).
- **MODIFIED** `src/ece-main.scm` — argv parsing for `ece-repl` learns the `--geiser` flag and passes it to the REPL function; the `repl` function branches on a `geiser?` parameter to choose the output formatting path.
- **MODIFIED** `Makefile` — `share/ece/ece-main.ecec` compile-system adds `src/geiser-ece.scm` to the file list.
- **DEPENDENCIES** — zero new CL libraries. Zero new elisp dependencies (Geiser itself is user-installed; we're a *backend* to it, not a fork). No Melpa release in day 1.

## Capabilities

### New Capabilities

- `geiser-backend` — the Geiser integration contract: CLI flag, structured wire protocol, Scheme-side request handlers (`geiser:eval`, `geiser:load-file`, `geiser:version`, `geiser:no-values`), elisp registration, and the observable day-1 behavior (eval form at point, load file, REPL buffer, error-safe eval loop).

### Modified Capabilities

- `repl` — gains a `--geiser` CLI flag that switches the output formatting path; error recovery is tightened so compilation failures don't pollute the bootstrap space (either in this change or a prereq PR cited here).

## Impact

- **Affected code**:
  - New: `emacs/geiser-ece.el`, `src/geiser-ece.scm`, `tests/ece/cl-only/test-geiser-ece.scm`, new test fixtures under `.tmp/` or `tests/ece/fixtures/`.
  - Modified: `src/ece-main.scm` (`--geiser` flag + branch in `repl`), `Makefile` (compile-system file list), possibly `bootstrap/primitives-auto.lisp` if a new introspection helper is needed for error-case output capture (most likely not — `current-output-port` parameterization already works).
- **Affected workflows**:
  - New: `M-x run-geiser` in emacs → pick `ece` → emacs spawns `bin/ece-repl --geiser` → `C-x C-e` / `C-c C-l` / REPL buffer work.
  - Unchanged: bare `bin/ece-repl` (no `--geiser`) still prints `(write result) (newline)` exactly as today.
  - Unchanged: `bin/ece`, `bin/ece-build`, `bin/ece-test`, `bin/ece-serve` all dispatch as before.
- **Performance**: trivial. One extra string conversion per REPL response (wrapping the value in an alist). Not on any hot path.
- **Test plan**:
  - Automated: Rove tests for `geiser:eval` / `geiser:load-file` / error handling / output capture / structured response shape, plus a subprocess test that spawns `bin/ece-repl --geiser` and verifies end-to-end.
  - Manual (user dogfooding): user installs `emacs/geiser-ece.el`, runs `M-x run-geiser`, picks `ece`, evaluates forms at point from `sandbox/programs/starfield.scm` or a trivial `fact.scm` test file.
- **Rollback**: revert the single implementation PR. The `--geiser` flag is opt-in; omitting it returns the REPL to identical pre-PR behavior. No schema, no migration, no state.
- **Relationship to the broader roadmap**:
  - **Day 1 (this change)**: CL host, bare Geiser backend, eval + load-file only.
  - **Day 2**: completions (needs `enumerate-global-env` introspection helper).
  - **Day 3**: autodoc (needs compiled-procedure arglist extraction).
  - **Day 4**: macroexpand (expose `*compile-time-macros*` through a `geiser:macroexpand` handler).
  - **Day 5**: jump-to-def (depends on source location tracking, roadmap thread 5).
  - **Day 6**: WASM host support — same wire protocol, different runtime transport (probably over stdin/stdout of a Node host running the WASM interpreter).
  - **Day 7**: attach-to-ece-serve mode — the "REPL-is-the-game" story where emacs talks to a running `ece serve` instead of spawning its own process.
  - Day 2+ are separate proposals; day 1 is the floor we need before any of them make sense.
