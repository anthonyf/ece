## ADDED Requirements

### Requirement: clear-screen clears the terminal
The `clear-screen` function SHALL clear the terminal screen by outputting ANSI escape sequences `ESC[2J` (erase display) and `ESC[H` (cursor home). It SHALL take no arguments and return nil.

#### Scenario: Clear screen output
- **WHEN** `(clear-screen)` is evaluated
- **THEN** the ANSI escape sequences SHALL be written to standard output and the function SHALL return `()`
