## Why

Day 2 shipped symbol completions — the user can now discover function names via `C-M-i`. But calling a function still requires remembering its exact parameter list. Autodoc (`eldoc-mode` in emacs) shows the function signature in the minibuffer as the cursor moves through a call form, which is the second-highest-leverage Geiser feature after completions.

ECE currently discards parameter names after compilation — compiled procedures store only an entry address and captured environment. A new metadata table is needed to preserve parameter lists at compile time, analogous to how `*procedure-name-table*` already preserves procedure names.

## What Changes

- **ADDED** `*procedure-params-table*` — CL-side hash table mapping entry addresses to parameter metadata `(params . rest?)`. Populated at assembly time by a new `%procedure-params-set!` primitive, alongside the existing `%procedure-name-set!` call.
- **ADDED** `%procedure-params` host primitive — returns the stored parameter metadata for a compiled procedure, or `#f` if unavailable. For host primitives, returns arity info from the manifest.
- **MODIFIED** compiler/assembler — emit `%procedure-params-set!` calls after lambda compilation to record parameter lists.
- **MODIFIED** `geiser-autodoc` in `src/geiser-ece.scm` — replace the stub with a real handler: looks up each identifier in the global env, calls `%procedure-params` to get parameter info, returns Geiser's expected autodoc format.
- **MODIFIED** `emacs/geiser-ece.el` — wire autodoc through the same direct REPL query mechanism used for completions (bypassing `geiser-eval--send/wait`), since the same Geiser internal eval channel issue from day 2 applies.

## Capabilities

### New Capabilities

- `procedure-introspection`: The `%procedure-params` primitive and the `*procedure-params-table*` metadata infrastructure for querying parameter names and arity at runtime.

### Modified Capabilities

- `geiser-backend`: Autodoc is no longer a stub — `geiser-autodoc` returns real parameter info for compiled procedures and primitives.

## Impact

- **Affected code**: `src/runtime.lisp` (new table + primitive), `src/compiler.scm` or `src/assembler.scm` (emit params metadata), `src/geiser-ece.scm` (autodoc handler), `emacs/geiser-ece.el` (autodoc wiring), `primitives.def` (new primitive ID), `src/primitives.scm` (new template), `src/boot-env.scm` (register).
- **Bootstrap**: Single-pass rebuild (`make bootstrap && make`) — new primitive + compiler change.
- **Performance**: `%procedure-params` is a hash-table lookup, O(1). Called once per cursor movement in eldoc mode, not on a hot path.
- **Rollback**: Revert the PR. Autodoc reverts to the empty stub. The params table adds ~10KB to the image but is harmless if unused.
