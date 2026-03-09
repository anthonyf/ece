## Why

The SICP 5.5 compiler was added alongside the existing interpreter, keeping the old interpreter code "for reference." This leaves ~500 lines of dead code in `src/ece.lisp`, an unused standalone assembler, outdated comments, and a README that still describes ECE as an interpreter. Removing this dead weight makes the codebase ~27% smaller and easier to navigate.

## What Changes

- Remove `evaluate-interpreted` (~500 lines) — the entire old interpreter, unreferenced by any code path
- Remove `make-procedure` — old interpreter's lambda representation, only used inside `evaluate-interpreted`
- Remove standalone `assemble` function — never called, replaced by `assemble-into-global`
- Remove dead runtime macro storage in `compile-define-macro` — stores `(macro ...)` values in `*global-env*` that nothing reads (compiler uses `*compile-time-macros*` hash table exclusively)
- Simplify `ece-load` to delegate to `compile-file-ece` instead of reimplementing the same read loop
- Fix outdated comments (line 716 "explicit control evaluator", line 721 "used by macro expansion during bootstrap")
- Update README to reflect compiler architecture

## Capabilities

### New Capabilities

_None — this is a pure cleanup change._

### Modified Capabilities

_None — no behavioral changes._

## Impact

- `src/ece.lisp`: ~524 lines removed, ~1400 lines remaining (down from ~1924)
- `README.md`: Updated description
- No behavioral changes — all existing tests must continue to pass unchanged
