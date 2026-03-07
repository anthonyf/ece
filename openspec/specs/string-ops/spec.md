## ADDED Requirements

### Requirement: string-length returns the length of a string
The evaluator SHALL provide `string-length` as a primitive.

#### Scenario: Length of a string
- **WHEN** evaluating `(string-length "hello")`
- **THEN** the result SHALL be `5`

#### Scenario: Length of empty string
- **WHEN** evaluating `(string-length "")`
- **THEN** the result SHALL be `0`

### Requirement: string-ref returns the character at an index
The evaluator SHALL provide `string-ref` that returns the character at a zero-based index.

#### Scenario: First character
- **WHEN** evaluating `(string-ref "hello" 0)`
- **THEN** the result SHALL be the character `h`

#### Scenario: Last character
- **WHEN** evaluating `(string-ref "hello" 4)`
- **THEN** the result SHALL be the character `o`

### Requirement: string-append concatenates strings
The evaluator SHALL provide `string-append` that concatenates two or more strings.

#### Scenario: Concatenate two strings
- **WHEN** evaluating `(string-append "hello" " world")`
- **THEN** the result SHALL be `"hello world"`

#### Scenario: Concatenate three strings
- **WHEN** evaluating `(string-append "a" "b" "c")`
- **THEN** the result SHALL be `"abc"`

#### Scenario: Concatenate with empty string
- **WHEN** evaluating `(string-append "" "hello")`
- **THEN** the result SHALL be `"hello"`

### Requirement: substring extracts a portion of a string
The evaluator SHALL provide `substring` that extracts characters from start index to end index.

#### Scenario: Extract substring
- **WHEN** evaluating `(substring "hello world" 0 5)`
- **THEN** the result SHALL be `"hello"`

#### Scenario: Extract from middle
- **WHEN** evaluating `(substring "hello world" 6 11)`
- **THEN** the result SHALL be `"world"`

### Requirement: string->number parses a number from a string
The evaluator SHALL provide `string->number` that converts a string to a number, or returns false if the string is not a valid number.

#### Scenario: Parse integer
- **WHEN** evaluating `(string->number "42")`
- **THEN** the result SHALL be `42`

#### Scenario: Parse negative number
- **WHEN** evaluating `(string->number "-7")`
- **THEN** the result SHALL be `-7`

#### Scenario: Invalid number returns false
- **WHEN** evaluating `(string->number "abc")`
- **THEN** the result SHALL be false

### Requirement: number->string converts a number to a string
The evaluator SHALL provide `number->string` that formats a number as a string.

#### Scenario: Integer to string
- **WHEN** evaluating `(number->string 42)`
- **THEN** the result SHALL be `"42"`

#### Scenario: Negative number to string
- **WHEN** evaluating `(number->string -7)`
- **THEN** the result SHALL be `"-7"`

### Requirement: string->symbol converts a string to a symbol
The evaluator SHALL provide `string->symbol` that interns a symbol from a string.

#### Scenario: String to symbol
- **WHEN** evaluating `(string->symbol "hello")`
- **THEN** the result SHALL be the symbol `hello`

#### Scenario: Round-trip with symbol->string
- **WHEN** evaluating `(equal? (string->symbol (symbol->string (quote foo))) (quote foo))`
- **THEN** the result SHALL be true

### Requirement: symbol->string converts a symbol to a string
The evaluator SHALL provide `symbol->string` that returns the name of a symbol as a lowercase string.

#### Scenario: Symbol to string
- **WHEN** evaluating `(symbol->string (quote hello))`
- **THEN** the result SHALL be `"hello"`

#### Scenario: Symbol name is lowercase
- **WHEN** evaluating `(symbol->string (quote FOO))`
- **THEN** the result SHALL be `"foo"`
