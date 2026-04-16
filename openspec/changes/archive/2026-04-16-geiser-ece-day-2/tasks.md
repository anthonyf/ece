## 1. Add %global-env-symbols host primitive

- [x] 1.1 Pick the next available primitive ID from `primitives.def` (after 236).
- [x] 1.2 Add `(ID %global-env-symbols 0 core "List all bound symbol names in global env")` to `primitives.def`.
- [x] 1.3 Add `(defun ece-%global-env-symbols () ...)` to `bootstrap/primitives-auto.lisp`: walk `*global-env*` to find the hash-frame, `maphash` to collect `(symbol-name key)` into a list, return it.
- [x] 1.4 Add `(%register-primitive! '%global-env-symbols ID)` to `src/boot-env.scm`.
- [x] 1.5 Add `(define-host-primitive (%global-env-symbols))` to `src/primitives.scm`.
- [x] 1.6 Run `make bootstrap && make` to rebuild with the new primitive.
- [x] 1.7 Verify at the REPL: `(%global-env-symbols)` returns a list of strings including `"map"` and `"+"`.

## 2. Implement geiser-completions handler

- [x] 2.1 In `src/geiser-ece.scm`, replace the `geiser-completions` stub with a real handler: call `(%global-env-symbols)`, filter by `string-prefix?` on the prefix arg, sort alphabetically, return the list.
- [x] 2.2 Verify `string-prefix?` exists in ECE's prelude. If not, implement it inline (~3 lines).
- [x] 2.3 Verify `sort` exists for string lists. If not, implement a simple insertion sort or use an existing helper.
- [x] 2.4 Rebuild `share/ece/ece-main.ecec` and `bin/ece` to pick up the new handler.

## 3. Wire elisp completions

- [x] 3.1 In `emacs/geiser-ece.el`, update `geiser-ece--geiser-procedure` so the `completions` case formats `(geiser-completions "prefix")`.
- [x] 3.2 Verify Geiser's generic completion machinery calls the `completions` proc — check if any additional elisp hooks are needed (e.g., `geiser-ece--completions` or similar).
- [x] 3.3 Test `C-M-i` in a `.scm` buffer: type `(str` then `C-M-i` and verify completion popup appears.
- [x] 3.4 Test TAB completion in the REPL buffer.

## 4. Tests

- [x] 4.1 In `tests/ece/cl-only/test-geiser-ece.scm`, add test: `(%global-env-symbols)` returns a list of strings.
- [x] 4.2 Add test: result includes `"map"`, `"+"`, `"car"`, `"cdr"`.
- [x] 4.3 Add test: after `(define test-completion-xyz 1)`, result includes `"test-completion-xyz"`.
- [x] 4.4 Add test: `(geiser-completions "string-")` returns a non-empty sorted list where every element starts with `"string-"`.
- [x] 4.5 Add test: `(geiser-completions "zzz-nonexistent")` returns `()`.
- [x] 4.6 Add test: `(geiser-completions "")` returns a non-empty list (all symbols).
- [x] 4.7 In `tests/ece.lisp`, add Rove test: `run-repl-geiser` with `(geiser-completions "str")` returns an alist whose result field contains string completion candidates.
- [x] 4.8 Run `make test-ece` and `make test-rove` — all green.

## 5. Regression + full test suite

- [x] 5.1 Run `make test` (full suite) — everything green modulo pre-existing failures.
- [x] 5.2 Verify `bin/ece-repl` still works without `--geiser`.
- [x] 5.3 Verify `bin/ece-repl --geiser` still handles eval and reader errors correctly.

## 6. Manual emacs dogfooding (user-driven)

- [x] 6.1 User reloads `emacs/geiser-ece.el`. Restarts Geiser REPL.
- [x] 6.2 In a `.scm` buffer, type `(str` then `C-M-i` — sees `string-append`, `string-length`, etc.
- [x] 6.3 In the REPL buffer, type `(ma` then TAB — sees `map`, etc. (%make-hash-table uses % prefix).
- [x] 6.4 Type `(zzz-nothing` then `C-M-i` — no candidates, no error.

## 7. Commit and PR

- [x] 7.1 Code-reviewer subagent pass on the full diff.
- [ ] 7.2 Archive the change: `/opsx:archive geiser-ece-day-2`.
- [ ] 7.3 Commit with message summarizing scope.
- [ ] 7.4 Open PR referencing PR #158 (day 1) as predecessor.
