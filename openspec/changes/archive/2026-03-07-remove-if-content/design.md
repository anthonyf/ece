## Context

ECE currently contains IF-specific files (`if-lib.scm`, `simple-game.scm`) at the project root, an IF roadmap (`openspec/roadmap-if.md`), and OpenSpec specs for IF-specific macros (`choose-macro`, `room-macro`, `sample-game`). The IF application is moving to a separate project that uses ECE as a library.

## Goals / Non-Goals

**Goals:**
- Remove all IF-specific files and specs from the ECE repository
- Keep ECE as a clean general-purpose language core

**Non-Goals:**
- Removing general-purpose features that happen to be useful for IF (save/load, call/cc, read-line, random, etc.)
- Changing any source code in `src/ece.lisp` or `src/prelude.scm`

## Decisions

### 1. Delete files, don't relocate

Simply delete the IF files. They're being rebuilt in the separate IF project, not moved.

### 2. Remove IF specs from openspec/specs/

Delete `choose-macro/`, `room-macro/`, and `sample-game/` from `openspec/specs/`. These specs describe IF library behavior, not ECE core behavior.

### 3. Remove IF roadmap

Delete `openspec/roadmap-if.md`. The IF roadmap belongs in the IF project.

### 4. Remove archived IF change

Delete `openspec/changes/archive/2026-03-07-add-if-library/`. This archived change documents IF library work that no longer belongs in this repo.

### 5. Keep save-load spec and archive

`save-load` is general-purpose continuation serialization. It stays.

## Risks / Trade-offs

- **No risk to functionality**: This is purely file deletion — no code changes to the evaluator, prelude, or tests.
- **History preserved in git**: All deleted content remains accessible in git history if needed.
