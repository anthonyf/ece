## Why

The normal boot path still loads `readtable.lisp` and `boot.lisp` as separate CL files, even though the ECE reader in the image handles all runtime reading. The CL readtable is only consumed by tests (`ece-eval-string`), and `boot.lisp` is 49 lines that belong in `runtime.lisp`. Removing these gets us to the target: **runtime.lisp + image load = full ECE system**.

## What Changes

- **Migrate `ece-eval-string` in tests** to route source strings through the ECE reader (in the image) instead of `*ece-readtable*`. The ~31 tests using `ece-eval-string` and ~4-8 tests with `#f`/`#t` in quoted s-expressions will be updated.
- **Merge `boot.lisp` into `runtime.lisp`** — the image load call, `evaluate`, `ece-try-eval`, and `repl` definitions (~49 lines) move to the bottom of `runtime.lisp`.
- **BREAKING**: Remove `readtable.lisp` from the `"ece"` ASDF system. `*ece-readtable*` is no longer available to production code or tests.
- **Remove `boot.lisp`** from the `"ece"` ASDF system (merged into `runtime.lisp`).
- Keep `readtable.lisp` and `compiler.lisp` in `"ece/cold"` for cold bootstrap only.

## Capabilities

### New Capabilities
- `ece-eval-string-via-mc`: Test helper that evaluates ECE source strings through the metacircular compiler's ECE reader instead of the CL readtable

### Modified Capabilities
- `boot-from-image`: boot.lisp is eliminated; its functionality merges into runtime.lisp. The ASDF system becomes just runtime.lisp (which loads the image and provides evaluate/repl).

## Impact

- `src/runtime.lisp` — gains boot.lisp content at the bottom
- `src/boot.lisp` — deleted from `"ece"` system
- `src/readtable.lisp` — removed from `"ece"` system (kept in `"ece/cold"`)
- `tests/ece.lisp` — `ece-eval-string` reimplemented; tests using `#f`/`#t` in quoted forms converted to string-based
- `ece.asd` — `"ece"` system simplified to just runtime.lisp
