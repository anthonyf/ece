## ADDED Requirements

### Requirement: read-line reads a line of text input as a string
The evaluator SHALL provide `read-line` as a primitive that reads a line of text from standard input and returns it as a string.

#### Scenario: read-line returns a string
- **WHEN** the user types "hello world" followed by enter
- **THEN** `(read-line)` SHALL return the string `"hello world"`

#### Scenario: read-line returns empty string for empty input
- **WHEN** the user presses enter without typing anything
- **THEN** `(read-line)` SHALL return the string `""`
