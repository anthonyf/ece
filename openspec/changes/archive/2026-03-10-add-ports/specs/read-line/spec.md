## MODIFIED Requirements

### Requirement: read-line reads a line of text input as a string
The evaluator SHALL provide `read-line` as a primitive that reads a line of text from a port and returns it as a string. When called with no arguments, it SHALL read from `current-input-port`. When called with a port argument, it SHALL read from that port.

#### Scenario: read-line returns a string
- **WHEN** the user types "hello world" followed by enter
- **THEN** `(read-line)` SHALL return the string `"hello world"`

#### Scenario: read-line returns empty string for empty input
- **WHEN** the user presses enter without typing anything
- **THEN** `(read-line)` SHALL return the string `""`

#### Scenario: read-line from port
- **WHEN** `(read-line (open-input-string "hello\nworld"))` is called
- **THEN** it SHALL return `"hello"`

#### Scenario: read-line returns EOF at end of port
- **WHEN** all lines have been read from a port and `read-line` is called again
- **THEN** it SHALL return the EOF sentinel
