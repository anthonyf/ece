## Why

`main.lisp` is a generic name. Renaming to `ece.lisp` better identifies the source and test files.

## What Changes

- Rename `src/main.lisp` to `src/ece.lisp`
- Rename `tests/main.lisp` to `tests/ece.lisp`
- Update `ece.asd` component references from `"main"` to `"ece"`

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- `ece.asd` — Update `:components` entries.
- `src/main.lisp` → `src/ece.lisp` — git mv.
- `tests/main.lisp` → `tests/ece.lisp` — git mv.
- FASL cache should be cleared after rename.
