## ADDED Requirements

### Requirement: lines joins arguments with newlines
`lines` SHALL accept any number of arguments and return a single string with each argument separated by a newline, with a trailing newline.

#### Scenario: Multiple lines
- **WHEN** `(lines "hello" "world")` is evaluated
- **THEN** the result SHALL be `"hello\nworld\n"`

#### Scenario: Single line
- **WHEN** `(lines "hello")` is evaluated
- **THEN** the result SHALL be `"hello\n"`

#### Scenario: Empty call
- **WHEN** `(lines)` is evaluated
- **THEN** the result SHALL be `""`

### Requirement: lines auto-stringifies non-string arguments
Non-string arguments to `lines` SHALL be converted to strings automatically.

#### Scenario: Mixed types
- **WHEN** `(lines "count:" 42)` is evaluated
- **THEN** the result SHALL be `"count:\n42\n"`
