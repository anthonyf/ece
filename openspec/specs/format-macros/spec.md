### Requirement: fmt concatenates values as strings
The evaluator SHALL provide `fmt` as a macro that concatenates its arguments into a single string, converting non-string values via `write-to-string`.

#### Scenario: Concatenate strings
- **WHEN** evaluating `(fmt "hello" " " "world")`
- **THEN** the result SHALL be `"hello world"`

#### Scenario: Mix strings and numbers
- **WHEN** evaluating `(fmt "You have " 5 " gold")`
- **THEN** the result SHALL be `"You have 5 gold"`

#### Scenario: Single string argument
- **WHEN** evaluating `(fmt "hello")`
- **THEN** the result SHALL be `"hello"`

#### Scenario: Number argument
- **WHEN** evaluating `(fmt 42)`
- **THEN** the result SHALL be `"42"`

### Requirement: print-text displays formatted text
The evaluator SHALL provide `print-text` as a macro that displays its arguments concatenated as a string (like `fmt` but outputs via `display`).

#### Scenario: Display formatted text
- **WHEN** evaluating `(print-text "You have " 5 " gold")`
- **THEN** the text `"You have 5 gold"` SHALL be displayed to standard output
