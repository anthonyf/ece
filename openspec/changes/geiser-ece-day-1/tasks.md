## 1. Research — ground the wire protocol in reality

- [ ] 1.1 Fetch and read a small existing Geiser backend (chibi or chicken) via `gh api` or `WebFetch`. Note the exact elisp registration API (`geiser-impl:define` / `geiser-implementation-help` / whatever the current Geiser version uses), the exact Scheme-side handler signatures, and the exact response format. Record findings in a short memory file or inline comment in `emacs/geiser-ece.el`.
- [ ] 1.2 Verify ECE reader limitations that may affect the wire protocol: `\r` in strings, `#x` hex literals, non-printable bytes in string literals. Plan the sentinel prefix around these constraints (e.g., avoid characters that would force escaping in the reader).
- [ ] 1.3 Confirm the exact shape Geiser expects for the `((result "...") (output "...") (error #f))` response — check whether it's an alist, a plist, or a list-of-values. Adjust the design before writing code if the assumption is wrong.

## 2. REPL error-recovery investigation + decision

- [ ] 2.1 Read `src/compiler.scm`'s `compile-and-go` entry point and trace how bootstrap-space labels get populated during REPL input compilation. Identify exactly where stale labels could be left on failure.
- [ ] 2.2 Prototype the fix: either a fresh throwaway space per REPL input, or a transactional label-table update that rolls back on compilation failure. Time-box to one workday.
- [ ] 2.3 Decide: bundle in this PR if the fix is localised (~50 lines), or extract to prereq PR `fix-repl-error-recovery` if it touches the assembler or executor. Document the decision in an updated note on this tasks.md.
- [ ] 2.4 If extracting: create the prereq change via `openspec new change fix-repl-error-recovery`, write a minimal proposal, land that PR first, and add a dependency note in this change.
- [ ] 2.5 If bundling: write a regression test that sends a compile-error expression followed by a successful expression to `repl` and verifies the second expression evaluates correctly. Live in `tests/ece/cl-only/test-repl-error-recovery.scm`.

## 3. `src/geiser-ece.scm` — Scheme-side handlers

- [ ] 3.1 Create `src/geiser-ece.scm` with a module header explaining the Geiser wire protocol and pointing at `openspec/changes/geiser-ece-day-1/design.md` for rationale.
- [ ] 3.2 Implement `%geiser-with-output-capture thunk`: install a fresh `open-output-string` port as `current-output-port` for the duration of `thunk`, return `(values thunk-result captured-output-string)`. Restore the previous port on normal and abnormal exit (use `dynamic-wind`).
- [ ] 3.3 Implement `(geiser:eval module expr)`: `%geiser-with-output-capture` around `(guard (e (#t <error-case>)) (evaluate expr))`, then build the structured alist response `((result "<written-value>") (output "<captured>") (error <#f-or-string>))`. Module arg is ignored in day 1.
- [ ] 3.4 Implement `(geiser:load-file path)`: same capture + guard pattern around `load`, return the same alist shape. Add a sanity check that `path` is a string and the file exists before calling `load`.
- [ ] 3.5 Implement `(geiser:version)`: return a non-empty string. Pull the value from whatever ECE already uses for `ece -V` so there's a single source of truth.
- [ ] 3.6 Implement `(geiser:no-values)`: return whatever Geiser recognizes as the no-values marker (likely `'no-values` or `(values)`). Confirm from task 1.3 findings.
- [ ] 3.7 Implement `(geiser:completions prefix)` and `(geiser:autodoc symbols)` as stub handlers that return empty results with `error #f`, so a day-1 backend handles Geiser's graceful-degradation feature checks.

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
