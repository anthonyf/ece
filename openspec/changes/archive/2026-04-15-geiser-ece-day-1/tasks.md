## 1. Research — ground the wire protocol in reality

- [x] 1.1 Fetched chibi's `geiser-chibi.el` + `src/geiser/geiser.scm` and guile's `src/geiser/emacs.scm` + `src/geiser/evaluation.scm` from gitlab.com/emacs-geiser. Findings: elisp registration is `define-geiser-implementation`, not `geiser-impl:define`. Minimum handlers for `C-x C-e` + `C-c C-l` are `eval`, `load-file`, `no-values` — unimplemented optionals are gracefully skipped by elisp, not errored/hung. No Scheme-side `geiser:version` — elisp runs `binary -V` via the `version-command` slot.
- [x] 1.2 N/A — no sentinel prefix needed. Real Geiser backends just `(write alist) (newline)` and rely on stdout redirection during eval to keep user-code output out of the wire stream. ECE reader limitations are moot for the wire protocol.
- [x] 1.3 Shape is `((result "<written-value>") (output . "<captured-output>"))` — alist with `output` as a **dotted pair** (not a list), **no error key**. Errors are prepended to `output` or captured via the same mechanism. Chibi (not guile) is the right template since it uses plain `define`d procedures. See updated `design.md` Decision 3.

## 2. REPL error-recovery investigation + decision

- [x] 2.1 Read `src/compiler.scm`'s `mc-compile-and-go`, `src/assembler.scm`'s `ece-assemble-into-global`, and the label-registration path. Traced empirically with `printf | bin/ece-repl`: compile errors, unbound variables, division-by-zero, type errors, and `(error "...")` all **already recover cleanly** in the current `.ecec`-boot world. The old "stale labels in bootstrap space" note referred to the pre-`.ecec` image-boot era and is no longer the live issue. The actual remaining bug is: **top-level reader errors crash the REPL**. ECE's reader (`src/reader.scm`) calls `error` → `raise` when it sees an unbalanced paren or unexpected EOF; `raise` has no installed handler in `(repl)` because `read` is invoked OUTSIDE `try-eval`, so it falls through to `%raw-error` → CL `error` → SBCL abort.
- [x] 2.2 Fix design: wrap the `(read)` call in `(repl)` with a `guard` that catches reader errors, prints them, and re-enters the loop without exiting. ~8-line change in `src/ece-main.scm`. No assembler/executor changes. Time-boxed investigation finished in ~1 hour.
- [x] 2.3 **Decision: BUNDLE in this PR.** Fix is tiny (~10 lines, localised to `src/ece-main.scm`'s `(repl)`), and it's load-bearing for Geiser's `C-c C-l` flow once `geiser:load-file` uses the same `guard` pattern internally.
- [ ] 2.4 N/A — fix is bundled, no prereq PR needed.
- [ ] 2.5 Regression test: send an unbalanced-paren expression followed by a successful expression to `repl`; verify the REPL prints an error for the first and returns the correct result for the second. Lives in `tests/ece/cl-only/test-repl-error-recovery.scm` (or inline in the existing `tests/ece.lisp` `repl` section).

## 3. `src/geiser-ece.scm` — Scheme-side handlers

- [ ] 3.1 Create `src/geiser-ece.scm` with a module header explaining the Geiser wire protocol and pointing at `openspec/changes/geiser-ece-day-1/design.md` for rationale.
- [ ] 3.2 Implement `%geiser-with-output-capture thunk`: install a fresh `open-output-string` port as `current-output-port` for the duration of `thunk`, return `(values thunk-result captured-output-string)`. Restore the previous port on normal and abnormal exit (use `dynamic-wind`).
- [ ] 3.3 Implement `(geiser:eval module form . rest)`: `%geiser-with-output-capture` around `(guard (e (#t <error-case>)) (evaluate form))`, then build the chibi-style alist `((result "<written-value>") (output . "<captured>"))`. `module` arg ignored in day 1 (elisp sends `#f` when no module). Errors: stringify the condition and prepend to `output`; `result` is still emitted as the empty string or the no-values marker.
- [ ] 3.4 Implement `(geiser:load-file path)`: same capture + guard pattern around `load`, return the same alist shape. Add a sanity check that `path` is a string and the file exists before calling `load`.
- [ ] 3.5 N/A — Geiser's elisp side reads ECE version via `binary -V` (the `version-command` slot), not via a Scheme-side `geiser:version` handler. Nothing to write on the Scheme side.
- [ ] 3.6 Implement `(geiser:no-values)`: return `#f` (chibi style). This is what Geiser reads when a form evaluates to no values.
- [ ] 3.7 Implement `(geiser:completions prefix . rest)` and `(geiser:autodoc ids . rest)` as stub handlers — both take `. rest` per chibi's shape since elisp sometimes sends extra args. Return empty lists in the same alist envelope so graceful-degradation feature probes succeed.

## 4. `--geiser` flag on `bin/ece-repl`

- [ ] 4.1 In `src/ece-main.scm`, extend `parse-argv` so `--geiser` is recognized as a boolean flag and passed through to `ece-repl-main` (and `ece-default-main` if it routes to `repl`).
- [ ] 4.2 Parameterize the `repl` function in `src/ece-main.scm` to accept a `geiser?` boolean. When true, output formatting switches from `(write result) (newline)` to calling a new `%geiser-format-response` helper from `src/geiser-ece.scm` that emits the sentinel-prefixed alist.
- [ ] 4.3 Preserve the existing `ece>` prompt unchanged in both modes so bare-terminal users see no difference.
- [ ] 4.4 Verify via manual shell session: `printf '(+ 1 2)\n' | bin/ece-repl` prints `3`; `printf '(+ 1 2)\n' | bin/ece-repl --geiser` prints the structured alist. Document the commands in a scratch note.

## 5. `emacs/geiser-ece.el` — elisp backend

- [ ] 5.1 Create `emacs/` directory with `geiser-ece.el` inside. File header credits ECE, links to the openspec change, and notes "load via `(load \"path/to/geiser-ece.el\")` in your init."
- [ ] 5.2 Register `ece` as a Geiser implementation using the API identified in task 1.1. Include: implementation name symbol (`'ece`), binary path (`bin/ece-repl`), args (`'("--geiser")`), prompt regex (`"ece> "`), and the handful of command handlers Geiser requires.
- [ ] 5.3 Define `geiser-ece--geiser-procedure`: format a Geiser request (`eval`, `load-file`, `no-values`, `version`) as a Scheme form that the `bin/ece-repl --geiser` subprocess will read and dispatch.
- [ ] 5.4 Define `geiser-ece--parameters` and prompt detection so Geiser knows when the subprocess is ready for the next request.
- [ ] 5.5 Define font-lock / paredit defaults for the ECE-mode major mode if needed. Most can inherit from `scheme-mode`.
- [ ] 5.6 Add a minimal `ece-mode` major mode (or reuse `scheme-mode` outright) so opening a `.scm` file gives font-lock + the Geiser keybindings (`C-x C-e`, `C-c C-l`, `C-c C-z`).

## 6. Makefile wiring

- [ ] 6.1 Add `src/geiser-ece.scm` to the `SHARE_FILES` list in `Makefile`.
- [ ] 6.2 Add `src/geiser-ece.scm` to the `share/ece/ece-main.ecec` target's `compile-system` invocation. Order: after `src/ece-main.scm` since `geiser-ece.scm` may reference REPL helpers.
- [ ] 6.3 Add `src/geiser-ece.scm` to the `WASM_TEST_SRCS` and the `test-ece` target's load list so tests can find it.
- [ ] 6.4 Update the `install` and `uninstall` targets so `src/geiser-ece.scm` lands under `$(PREFIX)/share/ece/`.

## 7. Tests — Scheme-side unit tests

- [ ] 7.1 Create `tests/ece/cl-only/test-geiser-ece.scm`. Platform-gate with `(when (platform-has? 'open-output-file) ...)` since the tests use `.tmp/` fixtures.
- [ ] 7.2 Test `geiser:eval #f '(+ 1 2)` → `result "3"`, `output ""`, `error #f`.
- [ ] 7.3 Test `geiser:eval #f '(begin (display "hi") 42)` → `result "42"`, `output "hi"`, `error #f`.
- [ ] 7.4 Test `geiser:eval #f '(error "boom")` → `error` non-`#f` with a message containing `"boom"`. Verify a second `geiser:eval` of a successful form works after the error.
- [ ] 7.5 Test `geiser:load-file` on a `.tmp/` fixture file containing `(define x 42)`: returns `error #f`, then `geiser:eval #f 'x` returns `result "42"`.
- [ ] 7.6 Test `geiser:load-file` on a `.tmp/` fixture with an unbalanced paren: returns `error` non-`#f`, subsequent `geiser:eval` still works.
- [ ] 7.7 Test `geiser:version` returns a non-empty string.
- [ ] 7.8 Test `geiser:completions` and `geiser:autodoc` return empty-but-well-formed responses.

## 8. Tests — Rove subprocess integration tests

- [ ] 8.1 Add `test-ece-repl-geiser-mode` to `tests/ece.lisp` that builds `bin/ece-repl` (via `asdf:system-relative-pathname`), spawns it via `sb-ext:run-program` with `--geiser`, pipes a single expression into stdin, reads stdout, and asserts the structured response shape.
- [ ] 8.2 Add a subprocess test for error recovery: send an error-raising form, read the response (expect `error` non-`#f`), send a successful form, read the response (expect `error #f`, correct `result`).
- [ ] 8.3 Add a subprocess test for `load-file` using a `.tmp/` fixture file.
- [ ] 8.4 Parse responses with a small helper that reads the sentinel prefix + alist using ECE's reader machinery (or CL's `read` if the format is a plain S-expression).

## 9. Regression + full test suite

- [ ] 9.1 Run `make test-ece` — all existing tests green plus the new `test-geiser-ece.scm` suite.
- [ ] 9.2 Run `make test-rove` — the new `test-ece-repl-geiser-mode` subprocess tests pass.
- [ ] 9.3 Run `make test-wasm` — the test file is CL-only-gated so WASM tests don't run the new cases; confirm no WASM regression.
- [ ] 9.4 Run `make test` (full suite) — everything green, modulo pre-existing unrelated failures.
- [ ] 9.5 Run `bin/ece` and confirm the REPL still starts normally without `--geiser`.
- [ ] 9.6 Run `bin/ece-repl --geiser` manually and confirm it produces the expected structured output for a trivial expression and an error.

## 10. Manual emacs dogfooding (user-driven)

- [ ] 10.1 User loads `emacs/geiser-ece.el` in their init. `M-x run-geiser` offers `ece`.
- [ ] 10.2 User selects `ece` → Geiser spawns `bin/ece-repl --geiser`. REPL buffer appears with the `ece> ` prompt.
- [ ] 10.3 User opens `sandbox/programs/starfield.scm` or a trivial `tests/ece/fixtures/fact.scm` test file, positions point after `(fact 10)`, hits `C-x C-e`, and sees the result in the minibuffer.
- [ ] 10.4 User uses `C-c C-l` to load the whole buffer. No errors, the defs are available in the REPL buffer.
- [ ] 10.5 User introduces a syntax error, saves, `C-c C-l`s, sees a clean error message, fixes it, `C-c C-l`s again, and continues without restarting the REPL.

## 11. Commit and PR

- [ ] 11.1 Code-reviewer subagent pass on the full diff before pushing. Apply fixes.
- [ ] 11.2 Contract audit + edge-case brainstorm: walk `geiser:eval` / `geiser:load-file` / output-capture interactions with errors, partial output, `dynamic-wind`, parameterize.
- [ ] 11.3 Run the full test suite one more time.
- [ ] 11.4 Archive the change in-PR per the `archive-before-merge` memory rule: `/opsx:archive geiser-ece-day-1` on the implementation branch, commit the directory move, include in the same PR.
- [ ] 11.5 Commit with a message summarizing the scope: `Add geiser-ece day-1 backend (CL host, eval + load-file + error recovery)`.
- [ ] 11.6 Open PR. Reference any error-recovery prereq PR if one was extracted. Link the design doc for reviewers.
