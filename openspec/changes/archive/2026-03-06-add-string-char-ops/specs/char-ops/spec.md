## ADDED Requirements

### Requirement: Characters are self-evaluating
Character literals written as `#\a`, `#\space`, `#\newline` etc. SHALL evaluate to themselves.

#### Scenario: Character literal self-evaluates
- **WHEN** evaluating `#\a`
- **THEN** the result SHALL be the character `a`

#### Scenario: Space character
- **WHEN** evaluating `#\space`
- **THEN** the result SHALL be the space character

### Requirement: char? tests for character type
The evaluator SHALL provide `char?` as a primitive that returns true for characters and false otherwise.

#### Scenario: Character is a char
- **WHEN** evaluating `(char? #\a)`
- **THEN** the result SHALL be true

#### Scenario: Number is not a char
- **WHEN** evaluating `(char? 42)`
- **THEN** the result SHALL be false

#### Scenario: String is not a char
- **WHEN** evaluating `(char? "a")`
- **THEN** the result SHALL be false

### Requirement: char=? compares characters for equality
The evaluator SHALL provide `char=?` as a primitive for character equality.

#### Scenario: Equal characters
- **WHEN** evaluating `(char=? #\a #\a)`
- **THEN** the result SHALL be true

#### Scenario: Unequal characters
- **WHEN** evaluating `(char=? #\a #\b)`
- **THEN** the result SHALL be false

### Requirement: char<? compares characters by ordering
The evaluator SHALL provide `char<?` as a primitive for character ordering.

#### Scenario: Less than
- **WHEN** evaluating `(char<? #\a #\b)`
- **THEN** the result SHALL be true

#### Scenario: Not less than
- **WHEN** evaluating `(char<? #\b #\a)`
- **THEN** the result SHALL be false

### Requirement: char->integer converts character to code point
The evaluator SHALL provide `char->integer` that returns the integer code point of a character.

#### Scenario: Character a code point
- **WHEN** evaluating `(char->integer #\a)`
- **THEN** the result SHALL be `97`

### Requirement: integer->char converts code point to character
The evaluator SHALL provide `integer->char` that returns the character for an integer code point.

#### Scenario: Code point 97 to character
- **WHEN** evaluating `(integer->char 97)`
- **THEN** the result SHALL be the character `a`

#### Scenario: Round-trip conversion
- **WHEN** evaluating `(char=? (integer->char (char->integer #\z)) #\z)`
- **THEN** the result SHALL be true
