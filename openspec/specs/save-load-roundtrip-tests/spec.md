## NEW Requirements

### Requirement: In-memory serialize/deserialize round-trip
`(deserialize-value (read (open-input-string (serialize-value V))))` SHALL return a value `equal?` to `V` for all supported ECE types.

#### Scenario: Fixnum
- **WHEN** V = `42`
- **THEN** the round-trip SHALL return `42`

#### Scenario: String
- **WHEN** V = `"hello world"`
- **THEN** the round-trip SHALL return `"hello world"`

#### Scenario: Symbol
- **WHEN** V = `(quote foo)`
- **THEN** the round-trip SHALL return the symbol `foo`

#### Scenario: Boolean true
- **WHEN** V = `#t`
- **THEN** the round-trip SHALL return `#t`

#### Scenario: Boolean false
- **WHEN** V = `#f`
- **THEN** the round-trip SHALL return `#f`

#### Scenario: Nil
- **WHEN** V = `(quote ())`
- **THEN** the round-trip SHALL return `()`

#### Scenario: Dotted pair
- **WHEN** V = `(cons 1 2)`
- **THEN** the round-trip SHALL return a pair with car=1, cdr=2

#### Scenario: Proper list
- **WHEN** V = `(list 1 2 3)`
- **THEN** the round-trip SHALL return `(1 2 3)`

#### Scenario: Nested list
- **WHEN** V = `(list (list 1 2) (list 3 4))`
- **THEN** the round-trip SHALL return `((1 2) (3 4))`

#### Scenario: Vector
- **WHEN** V = `(vector 1 2 3)`
- **THEN** the round-trip SHALL return `#(1 2 3)`

### Requirement: File-based save/load round-trip
`(begin (save-continuation! F V) (load-continuation F))` SHALL return a value `equal?` to `V`.

#### Scenario: Save and load list
- **WHEN** V = `(list 1 2 3)` and F = a temp file path
- **THEN** `load-continuation` SHALL return `(1 2 3)`

#### Scenario: Save and load nested structure
- **WHEN** V = `(list (vector 1 2) (cons 3 4))`
- **THEN** `load-continuation` SHALL return an `equal?` structure

### Requirement: Shared structure round-trip
Values appearing multiple times in a tree SHALL serialize with `%ser/def` / `%ser/ref` tags and round-trip correctly.

#### Scenario: Shared sublist
- **GIVEN** `(let ((x (list 1 2))) (list x x))`
- **WHEN** round-tripped through serialize/deserialize
- **THEN** the result SHALL be `equal?` to the original
