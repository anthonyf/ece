## ADDED Requirements

### Requirement: Sample game loads the IF library
The sample game file SHALL begin with `(load "if-lib.scm")` to load the IF framework.

#### Scenario: Game loads without error
- **WHEN** evaluating `(load "simple-game.scm")`
- **THEN** the IF library and game definitions SHALL load without error

### Requirement: Sample game defines multiple interconnected rooms
The sample game SHALL define at least 3 rooms using the `room` macro, connected by choices that navigate between them.

#### Scenario: Rooms are navigable
- **WHEN** the player starts the game
- **THEN** the player SHALL be able to navigate between rooms via `choose` menus

### Requirement: Sample game demonstrates conditional choices
The sample game SHALL include at least one choice guarded by a `when` clause (e.g., an action available only when a game variable meets a condition).

#### Scenario: Guarded choice appears when condition met
- **WHEN** the guard condition is truthy
- **THEN** the conditional choice SHALL appear in the menu
