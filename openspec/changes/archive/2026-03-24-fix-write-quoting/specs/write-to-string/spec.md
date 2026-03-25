## MODIFIED Requirements

### Requirement: write quotes strings and characters
`write` SHALL produce readable output: strings wrapped in `"..."`, characters as `#\c`.

#### Scenario: write quotes strings
- **WHEN** `(write "hello")` is called
- **THEN** the output SHALL be `"hello"` (with literal quote characters)

#### Scenario: display does not quote strings
- **WHEN** `(display "hello")` is called
- **THEN** the output SHALL be `hello` (no quotes)

#### Scenario: write quotes strings in lists
- **WHEN** `(write (list "a" "b"))` is called
- **THEN** the output SHALL be `("a" "b")` (each string quoted)

#### Scenario: write to port quotes strings
- **WHEN** `(write "hello" port)` is called on an output port
- **THEN** the port SHALL receive `"hello"` (with quotes)
