## Why

Day 1 shipped a working Geiser backend — `C-x C-e` evaluates, `C-c C-l` loads files, the REPL buffer works. But typing code without completions feels like writing blind: the user has to remember every symbol name exactly. Symbol completion (`C-M-i` / TAB in the REPL) is the single highest-leverage feature for day 2 because it makes the existing eval path dramatically more useful without touching the wire protocol or adding new evaluation machinery.

ECE currently has no introspection hook for enumerating global bindings. The global environment is a hash-frame (`(:hash-frame . <hash-table>)`) in `*global-env*`, but there's no primitive to list its keys from ECE code. Adding one unlocks completions and is a building block for future features (inspector, symbol documentation, module browser).

## What Changes

- **ADDED** `%global-env-symbols` host primitive — enumerates all bound symbol names from `*global-env*`'s hash-frame, returning a list of strings. CL-side: one `maphash` over the hash-table, collecting `(symbol-name key)` for each entry. ~5 lines in `primitives-auto.lisp`, registered in `primitives.def` and `boot-env.scm`.
- **MODIFIED** `geiser-completions` in `src/geiser-ece.scm` — replace the day-1 empty stub with a real handler: calls `%global-env-symbols`, filters by `string-prefix?`, returns the matching list as a sorted list of strings.
- **MODIFIED** `emacs/geiser-ece.el` — wire `geiser-ece--geiser-procedure` to format `completions` requests as `(geiser-completions "prefix")`, so Geiser's `C-M-i` and REPL TAB call the handler and display results.
- **ADDED** tests: ECE-side unit tests for `%global-env-symbols` (returns strings, includes known builtins) and `geiser-completions` (prefix filtering, empty prefix, no-match). Rove integration test that exercises completions through the `--geiser` REPL mode.
- **MODIFIED** `Makefile` — bootstrap rebuild for the new primitive ID (single-pass, no migration needed).

## Capabilities

### New Capabilities

- `global-env-introspection`: The `%global-env-symbols` primitive and the contract for enumerating the global environment's bound names.

### Modified Capabilities

- `geiser-backend`: Completions are no longer a stub — `geiser-completions` returns real prefix-filtered results from the global environment.

## Impact

- **Affected code**: `bootstrap/primitives-auto.lisp` (new defun), `primitives.def` (new ID), `src/boot-env.scm` (register), `src/geiser-ece.scm` (completions handler), `emacs/geiser-ece.el` (completions wiring), `tests/ece/cl-only/test-geiser-ece.scm` (new tests), `tests/ece.lisp` (Rove test).
- **Bootstrap**: Single-pass rebuild (`make bootstrap && make`) — new primitive, no migration.
- **Performance**: `%global-env-symbols` walks the entire global hash-table (~750+ entries). Called once per TAB press, not on a hot path. If it's slow, we can cache later.
- **Rollback**: Revert the PR. Completions revert to the empty stub. No state, no migration.
