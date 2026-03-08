## Context

ECE has no build/task automation. Common tasks (running tests, launching REPL, clearing caches) require remembering long `qlot exec sbcl` commands. The Dunge project has a working Makefile and Emacs-based formatting pipeline that serves as the template.

## Goals / Non-Goals

**Goals:**
- One-command access to test, repl, fmt, and clean operations
- Automated formatting check on commit via pre-commit hook
- Format `.lisp`/`.asd` files with CL indentation and `.scm` files with Scheme indentation

**Non-Goals:**
- CI integration for formatting (can be added later)
- Editor-specific configuration beyond the batch scripts

## Decisions

### Two indent scripts: cl-indent.el and scheme-indent.el
`.lisp`/`.asd` files use `common-lisp-indent-function` (via `cl-indent.el` from Dunge). `.scm` files use Emacs `scheme-mode` indentation, which handles Scheme forms correctly. A separate `scheme-indent.el` script switches to `scheme-mode` before indenting.

### Pre-commit hook via symlink
`make setup` creates a symlink from `.git/hooks/pre-commit` to `scripts/pre-commit`. This keeps the hook version-controlled and easy to update. Same pattern as Dunge.

### check-fmt runs fmt then checks for diffs
`make check-fmt` formats files in-place, then uses `git diff --quiet` to detect changes. If any files changed, formatting was wrong — it restores them and exits non-zero. This avoids needing a separate "check-only" mode.

## Risks / Trade-offs

- **Emacs required for formatting** → Acceptable since both developers use Emacs. Document in Makefile or README.
- **scheme-indent.el may not know ECE-specific forms** → Basic s-expression indentation is still correct; ECE macros follow standard Scheme conventions.
