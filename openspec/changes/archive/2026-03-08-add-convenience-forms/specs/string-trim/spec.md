## ADDED Requirements

### Requirement: string-trim removes leading and trailing whitespace
`string-trim` SHALL accept a string and return a new string with leading and trailing whitespace (spaces, tabs, newlines) removed.

#### Scenario: Trim spaces
- **WHEN** `(string-trim "  hello  ")` is evaluated
- **THEN** the result SHALL be `"hello"`

#### Scenario: Trim tabs and newlines
- **WHEN** a string with leading tab and trailing newline is trimmed
- **THEN** both SHALL be removed

#### Scenario: No whitespace
- **WHEN** `(string-trim "hello")` is evaluated
- **THEN** the result SHALL be `"hello"`

#### Scenario: All whitespace
- **WHEN** `(string-trim "   ")` is evaluated
- **THEN** the result SHALL be `""`

#### Scenario: Empty string
- **WHEN** `(string-trim "")` is evaluated
- **THEN** the result SHALL be `""`
