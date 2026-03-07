## Why

ECE's core language now has all the primitives needed for interactive fiction (read-line, fmt, random, etc.), but there's no IF-specific layer yet. Authors need macros for defining rooms and presenting choices — the two fundamental building blocks of choice-based IF. A loadable library and sample game will validate the design and serve as a reference for IF authors.

## What Changes

- Update `openspec/roadmap-if.md` with the prioritized implementation plan from the explore session
- Create `if-lib.scm` — a loadable ECE library providing:
  - `room` macro for defining rooms with description text and body
  - `choose` macro for presenting numbered choice menus with conditional guards, dispatching to actions via `read-line` input
- Create `simple-game.scm` — a small playable game that loads `if-lib.scm` and uses `room` and `choose` to define several interconnected rooms, demonstrating goto navigation and conditional choices

## Capabilities

### New Capabilities
- `room-macro`: The `room` macro for defining IF rooms with description text
- `choose-macro`: The `choose` macro for presenting numbered choice menus, reading player input, and dispatching to actions
- `sample-game`: A simple playable game validating the IF library design

### Modified Capabilities

(none)

## Impact

- New files: `if-lib.scm`, `simple-game.scm` in project root
- Updated file: `openspec/roadmap-if.md`
- No changes to `src/main.lisp` or `tests/main.lisp` — this is pure ECE-level code
