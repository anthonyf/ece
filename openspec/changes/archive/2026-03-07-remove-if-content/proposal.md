## Why

ECE is a standalone general-purpose language that can be used for interactive fiction among other things. The IF library and sample game are being developed in a separate project that uses ECE as a library. Having IF-specific code and specs in the core ECE repo conflates the language with one application domain.

## What Changes

- Remove `if-lib.scm` (IF library with `room`, `choose`, `display-choices` macros)
- Remove `simple-game.scm` (sample IF game)
- Remove `openspec/roadmap-if.md` (IF-specific roadmap)
- Remove IF-specific OpenSpec specs: `choose-macro`, `room-macro`, `sample-game`
- Remove archived IF-related change: `2026-03-07-add-if-library`
- General-purpose features stay: `save-load`, `call/cc`, `read-line`, `random`, `fmt`, etc.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `choose-macro`: REMOVED — IF-specific, moving to separate project
- `room-macro`: REMOVED — IF-specific, moving to separate project
- `sample-game`: REMOVED — IF-specific, moving to separate project

## Impact

- No code changes to `src/ece.lisp` or `src/prelude.scm` — only file deletions
- No test changes — no IF-specific tests exist in the test suite
- No API changes — all general-purpose primitives remain
