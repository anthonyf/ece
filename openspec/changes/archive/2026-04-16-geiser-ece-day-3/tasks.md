## 1. Add procedure parameter metadata infrastructure

- [x] 1.1 Add `*procedure-params-table*` to `src/runtime.lisp` (hash table, entry-address → `(param-names . rest?)`).
- [x] 1.2 Add `%procedure-params-set!` primitive: pick next ID from `primitives.def` (238), add to `primitives.def`, `src/primitives.scm`, `src/boot-env.scm`.
- [x] 1.3 Add `%procedure-params` primitive (ID 239): look up entry address in `*procedure-params-table*`, return `(param-names . rest?)` or `#f`. For primitives, return arity from manifest.
- [x] 1.4 Add stub to `bootstrap/primitives-auto.lisp` for both new primitives (needed for bootstrap).
- [x] 1.5 Run `make bootstrap && make` — verify builds.

## 2. Emit parameter metadata from compiler/assembler

- [x] 2.1 In `src/assembler.scm` (or `src/compiler.scm`), find where `%procedure-name-set!` is emitted after lambda compilation.
- [x] 2.2 Add a `%procedure-params-set!` call at the same point, passing the entry address and `(param-names . rest?)` from the lambda form.
- [x] 2.3 Run `make bootstrap && make` (two-pass if compiler changed).
- [x] 2.4 Verify at REPL: `(%procedure-params map)` returns parameter metadata.
- [x] 2.5 Verify: `(%procedure-params car)` returns arity info for a host primitive.

## 3. Implement geiser-autodoc handler

- [x] 3.1 In `src/geiser-ece.scm`, replace the `geiser-autodoc` stub with a real handler: for each identifier, look up in global env, call `%procedure-params`, format as `((name (args (required p1 p2) (optional) (key))))`.
- [x] 3.2 Handle rest-params: put the rest parameter in a separate position per Geiser's format.
- [x] 3.3 Handle missing identifiers gracefully (return `()` for unknowns).
- [x] 3.4 Rebuild and verify at REPL: `(geiser-autodoc '(map))` returns formatted autodoc.

## 4. Wire elisp autodoc

- [x] 4.1 In `emacs/geiser-ece.el`, add `geiser-ece--sync-autodoc` using the same comint-redirect pattern as completions.
- [x] 4.2 Add `geiser-ece--eldoc-function` that extracts the function name at point, queries autodoc, and formats for eldoc display.
- [x] 4.3 Hook into `eldoc-documentation-function` via `geiser-mode-hook` and `geiser-repl-mode-hook`.
- [x] 4.4 Test in emacs: position cursor inside `(map |` — see signature in minibuffer.

## 5. Tests

- [x] 5.1 ECE unit test: `(%procedure-params)` returns metadata for a defined procedure.
- [x] 5.2 ECE unit test: `(%procedure-params)` returns `#f` for non-procedures.
- [x] 5.3 ECE unit test: `(%procedure-params)` returns arity for host primitives.
- [x] 5.4 ECE unit test: `(geiser-autodoc '(map))` returns non-empty alist.
- [x] 5.5 ECE unit test: `(geiser-autodoc '(zzz-nonexistent))` returns `()`.
- [x] 5.6 Rove integration test: `run-repl-geiser` with `(geiser-autodoc '(map))` returns structured result.
- [x] 5.7 Run `make test-ece` and `make test-rove` — all green.

## 6. Regression + full test suite

- [x] 6.1 Run `make test` (full suite) — everything green modulo pre-existing failures.
- [x] 6.2 Verify `bin/ece-repl` normal mode still works.
- [x] 6.3 Verify completions (`C-M-i`) still work after the changes.

## 7. Manual emacs dogfooding (user-driven)

- [x] 7.1 User reloads `geiser-ece.el`. Restarts Geiser REPL.
- [x] 7.2 Position cursor inside `(map |` — sees signature in minibuffer.
- [x] 7.3 Position cursor inside `(string-append |` — sees signature.
- [x] 7.4 Position cursor inside `(car |` — sees primitive arity.
- [x] 7.5 Position cursor inside `(zzz-unknown |` — no signature, no error.

## 8. Commit and PR

- [x] 8.1 Code-reviewer subagent pass on the full diff.
- [ ] 8.2 Archive the change: `/opsx:archive geiser-ece-day-3`.
- [ ] 8.3 Commit with message summarizing scope.
- [ ] 8.4 Open PR referencing PR #159 (day 2) as predecessor.
