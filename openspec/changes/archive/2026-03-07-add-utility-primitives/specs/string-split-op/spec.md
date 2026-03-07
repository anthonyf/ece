## ADDED Requirements

### Requirement: string-split splits a string by delimiter
The `string-split` function SHALL accept a string and an optional delimiter character (defaulting to `#\Space`). It SHALL return a list of substrings split at each occurrence of the delimiter. Empty substrings from consecutive delimiters SHALL be included.

#### Scenario: Split by space (default)
- **WHEN** `(string-split "hello world")` is evaluated
- **THEN** it SHALL return `("hello" "world")`

#### Scenario: Split by explicit delimiter
- **WHEN** `(string-split "a,b,c" #\,)` is evaluated
- **THEN** it SHALL return `("a" "b" "c")`

#### Scenario: No delimiter found
- **WHEN** `(string-split "hello" #\,)` is evaluated
- **THEN** it SHALL return `("hello")`

#### Scenario: Empty string
- **WHEN** `(string-split "" #\,)` is evaluated
- **THEN** it SHALL return `("")`
