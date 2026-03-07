### Requirement: write-to-string converts any value to its string representation
The evaluator SHALL provide `write-to-string` as a primitive that converts any ECE value to a human-readable string (without escape characters).

#### Scenario: Number to string
- **WHEN** evaluating `(write-to-string 42)`
- **THEN** the result SHALL be `"42"`

#### Scenario: Symbol to string
- **WHEN** evaluating `(write-to-string (quote hello))`
- **THEN** the result SHALL be `"HELLO"`

#### Scenario: String passes through
- **WHEN** evaluating `(write-to-string "hello")`
- **THEN** the result SHALL be `"hello"`

#### Scenario: Boolean to string
- **WHEN** evaluating `(write-to-string #t)`
- **THEN** the result SHALL be `"T"`

#### Scenario: List to string
- **WHEN** evaluating `(write-to-string (quote (1 2 3)))`
- **THEN** the result SHALL be `"(1 2 3)"`

#### Scenario: Empty list to string
- **WHEN** evaluating `(write-to-string (quote ()))`
- **THEN** the result SHALL be `"NIL"`
