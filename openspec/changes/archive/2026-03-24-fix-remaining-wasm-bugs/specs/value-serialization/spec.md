## MODIFIED Requirements

### Requirement: write-to-string quotes strings
`write-to-string-flat` SHALL produce Scheme `write`-style output for strings: wrapped in double quotes with `\` and `"` characters escaped.

#### Scenario: Simple string
- **WHEN** `(write-to-string-flat "hello")` is called
- **THEN** the result SHALL be `"\"hello\""` (a 7-character string containing the quotes)

#### Scenario: String with special characters
- **WHEN** `(write-to-string-flat "say \"hi\"")` is called
- **THEN** the result SHALL contain escaped quotes: `"\"say \\\"hi\\\"\""`

#### Scenario: String round-trip via serializer
- **WHEN** `(deserialize-value (read (open-input-string (serialize-value "hello world"))))` is called
- **THEN** the result SHALL be the string `"hello world"`
