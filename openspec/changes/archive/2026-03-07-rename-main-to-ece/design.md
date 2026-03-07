## Context

Simple file rename — no architectural decisions needed.

## Goals / Non-Goals

**Goals:**
- Rename source and test files from `main.lisp` to `ece.lisp`.

**Non-Goals:**
- No code changes, no splitting files.

## Decisions

### Decision 1: Use `git mv` for rename
Preserves git history tracking.

## Risks / Trade-offs

- FASL cache will have stale entries for the old filenames. Clear after rename.
