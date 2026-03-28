## MODIFIED Requirements

### Requirement: hash-ref returns default when key not found
When `hash-ref` is called with 3 arguments and the key is not found, it SHALL return the 3rd argument instead of `#f`.

#### Scenario: hash-ref with default
- **WHEN** `(hash-ref ht 'missing 'default)` is called and `'missing` is not in `ht`
- **THEN** it SHALL return `'default`

### Requirement: string->number handles all test inputs correctly
The `string->number` primitive SHALL correctly parse all inputs tested by `test-strings.scm`.

#### Scenario: string->number for integers and floats
- **WHEN** `(string->number "0")`, `(string->number "42")`, `(string->number "3.14")` are called
- **THEN** they SHALL return `0`, `42`, `3.14` respectively

### Requirement: make-parameter applies converter
When `make-parameter` is called with a converter function, the converter SHALL be applied to the initial value.

#### Scenario: make-parameter with string-length converter
- **WHEN** `(make-parameter "hello" string-length)` is called
- **THEN** the parameter's value SHALL be `5`
