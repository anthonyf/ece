## ADDED Requirements

### Requirement: string-contains? tests for substring presence
`string-contains?` SHALL accept two string arguments (haystack, needle) and return `#t` if the needle is found in the haystack, `()` otherwise.

#### Scenario: Substring found
- **WHEN** `(string-contains? "hello world" "world")` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: Substring not found
- **WHEN** `(string-contains? "hello world" "xyz")` is evaluated
- **THEN** the result SHALL be `()`

#### Scenario: Empty needle
- **WHEN** `(string-contains? "hello" "")` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: Case sensitive
- **WHEN** `(string-contains? "Hello" "hello")` is evaluated
- **THEN** the result SHALL be `()`

### Requirement: string-join concatenates a list with separator
`string-join` SHALL accept a list of strings and a separator string, and return a single string with elements joined by the separator.

#### Scenario: Join with comma
- **WHEN** `(string-join (list "a" "b" "c") ", ")` is evaluated
- **THEN** the result SHALL be `"a, b, c"`

#### Scenario: Join with empty separator
- **WHEN** `(string-join (list "a" "b" "c") "")` is evaluated
- **THEN** the result SHALL be `"abc"`

#### Scenario: Single element
- **WHEN** `(string-join (list "hello") "-")` is evaluated
- **THEN** the result SHALL be `"hello"`

#### Scenario: Empty list
- **WHEN** `(string-join (list) ", ")` is evaluated
- **THEN** the result SHALL be `""`
