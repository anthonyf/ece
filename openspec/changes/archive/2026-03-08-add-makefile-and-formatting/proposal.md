## Why

ECE has no standard way to run common tasks (test, repl, clean) or enforce code formatting. The Dunge project already has a working Makefile and Emacs-based formatting pipeline that can be adapted.

## What Changes

- Add `scripts/cl-indent.el` — Emacs batch indentation script (copied from Dunge)
- Add `scripts/scheme-indent.el` — Emacs batch indentation for `.scm` files using Scheme mode
- Add `scripts/pre-commit` — Git hook that runs `make check-fmt` on staged `.lisp`, `.asd`, and `.scm` files
- Add `Makefile` with targets:
  - `test` — run the test suite via qlot/rove
  - `repl` — launch ECE REPL
  - `fmt` — format all source files
  - `check-fmt` — verify formatting (used by pre-commit hook)
  - `setup` — install pre-commit hook via symlink
  - `clean` — clear FASL cache

## Capabilities

### New Capabilities
- `makefile`: Makefile with test, repl, fmt, check-fmt, setup, and clean targets
- `formatting-hook`: Pre-commit hook that enforces consistent indentation on `.lisp`, `.asd`, and `.scm` files

### Modified Capabilities

None.

## Impact

- New files: `Makefile`, `scripts/cl-indent.el`, `scripts/scheme-indent.el`, `scripts/pre-commit`
- No changes to existing source code
- Developers run `make setup` once to install the hook
