### Requirement: choose macro displays a numbered menu of choices
The IF library SHALL provide a `choose` macro that displays available choices as a numbered list and reads the player's selection.

#### Scenario: Display choices
- **WHEN** evaluating a `choose` form with three unconditional choices
- **THEN** the choices SHALL be displayed as a numbered list (1, 2, 3) with their label text

### Requirement: choose macro reads player input and dispatches
The `choose` macro SHALL read a number from standard input via `read-line`, validate it, and execute the corresponding choice's action.

#### Scenario: Valid selection
- **WHEN** the player enters a valid number corresponding to a displayed choice
- **THEN** the action expression for that choice SHALL be evaluated

#### Scenario: Invalid selection re-prompts
- **WHEN** the player enters an invalid number or non-numeric input
- **THEN** an error message SHALL be displayed and the player SHALL be prompted again

### Requirement: choose macro supports conditional choices
The `choose` macro SHALL support `(when guard ("label" action))` clauses that only appear when the guard expression is truthy.

#### Scenario: Guard is true
- **WHEN** a choice has a `when` guard that evaluates to truthy
- **THEN** that choice SHALL appear in the numbered menu

#### Scenario: Guard is false
- **WHEN** a choice has a `when` guard that evaluates to falsy
- **THEN** that choice SHALL NOT appear in the numbered menu and numbering SHALL adjust accordingly

### Requirement: choose macro supports unconditional choices
The `choose` macro SHALL support `("label" action)` clauses without guards.

#### Scenario: Unconditional choice always appears
- **WHEN** a choice has no `when` guard
- **THEN** that choice SHALL always appear in the menu
