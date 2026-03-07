## ADDED Requirements

### Requirement: string-downcase converts to lowercase
The `string-downcase` function SHALL accept a string and return a new string with all characters converted to lowercase.

#### Scenario: Mixed case input
- **WHEN** `(string-downcase "Hello World")` is evaluated
- **THEN** it SHALL return `"hello world"`

#### Scenario: Already lowercase
- **WHEN** `(string-downcase "hello")` is evaluated
- **THEN** it SHALL return `"hello"`

### Requirement: string-upcase converts to uppercase
The `string-upcase` function SHALL accept a string and return a new string with all characters converted to uppercase.

#### Scenario: Mixed case input
- **WHEN** `(string-upcase "Hello World")` is evaluated
- **THEN** it SHALL return `"HELLO WORLD"`

#### Scenario: Already uppercase
- **WHEN** `(string-upcase "HELLO")` is evaluated
- **THEN** it SHALL return `"HELLO"`
