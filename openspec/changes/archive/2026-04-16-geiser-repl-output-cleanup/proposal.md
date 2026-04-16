## Why

The Geiser REPL buffer displays raw wire protocol alists instead of clean results. When the user evaluates `(+ 1 2)` in the REPL, they see `((result "3") (output . ""))` instead of just `3`. This makes the REPL buffer unusable for interactive development — the signal is buried in protocol noise. `C-x C-e` works cleanly (Geiser parses the alist and shows just the result in the minibuffer), but the REPL buffer itself is the primary interactive surface.

## What Changes

- **MODIFIED** `emacs/geiser-ece.el` — add a comint output filter that intercepts the raw alist responses in the REPL buffer, extracts the `result` and `output` fields, and displays them cleanly. Output from `display`/`write` appears first, then the result value on its own line.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `geiser-backend`: REPL buffer displays clean results instead of raw alist wire protocol.

## Impact

- **Affected code**: `emacs/geiser-ece.el` only — this is a pure elisp presentation change.
- **Bootstrap**: None required — no Scheme-side changes.
- **Rollback**: Remove the output filter. REPL reverts to showing raw alists.
