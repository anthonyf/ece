## 1. Update Roadmap

- [x] 1.1 Update `openspec/roadmap-if.md` to mark step 1 as complete, update "What ECE Has Today" table with new primitives, and reflect the prioritized plan

## 2. IF Library Core

- [x] 2.1 Create `if-lib.scm` with `display-choices` helper function (displays numbered list of choice pairs)
- [x] 2.2 Implement `choose-loop` helper function (displays menu, reads input, validates, dispatches)
- [x] 2.3 Implement `choose` macro that expands clauses into a list of `(label . thunk)` pairs, handling `when` guards, and calls `choose-loop`
- [x] 2.4 Implement `room` macro that defines a function, displays description text, and evaluates body

## 3. Sample Game

- [x] 3.1 Create `simple-game.scm` that loads `if-lib.scm` and defines 3-5 interconnected rooms using `room` and `choose`, with at least one conditional choice guarded by a variable

## 4. Validation

- [x] 4.1 Manually test the game by loading `simple-game.scm` in the ECE REPL and verifying room navigation and conditional choices work correctly
