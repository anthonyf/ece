## Requirements

### Requirement: char=? implemented in ECE
`char=?` SHALL be implemented in `prelude.scm` as `(= (char->integer a) (char->integer b))`.

#### Scenario: equal characters
- **WHEN** `(char=? #\a #\a)` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: unequal characters
- **WHEN** `(char=? #\a #\b)` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: char<? implemented in ECE
`char<?` SHALL be implemented in `prelude.scm` as `(< (char->integer a) (char->integer b))`.

#### Scenario: less-than true
- **WHEN** `(char<? #\a #\b)` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: less-than false
- **WHEN** `(char<? #\b #\a)` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: string=? implemented in ECE
`string=?` SHALL be implemented in `prelude.scm` as character-by-character equality comparison using `string-length`, `string-ref`, and `char=?`.

#### Scenario: equal strings
- **WHEN** `(string=? "hello" "hello")` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: unequal strings
- **WHEN** `(string=? "hello" "world")` is evaluated
- **THEN** the result SHALL be `#f`

#### Scenario: different lengths
- **WHEN** `(string=? "hi" "high")` is evaluated
- **THEN** the result SHALL be `#f`

#### Scenario: empty strings
- **WHEN** `(string=? "" "")` is evaluated
- **THEN** the result SHALL be `#t`

### Requirement: string<? implemented in ECE
`string<?` SHALL be implemented in `prelude.scm` as lexicographic comparison using `string-length`, `string-ref`, and `char<?`.

#### Scenario: less-than true
- **WHEN** `(string<? "abc" "abd")` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: prefix is less
- **WHEN** `(string<? "ab" "abc")` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: less-than false
- **WHEN** `(string<? "b" "a")` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: string>? implemented in ECE
`string>?` SHALL be implemented in `prelude.scm` by delegating to `string<?` with swapped arguments.

#### Scenario: greater-than true
- **WHEN** `(string>? "b" "a")` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: greater-than false
- **WHEN** `(string>? "a" "b")` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: vector->list implemented in ECE
`vector->list` SHALL be implemented in `prelude.scm` by iterating from the last index to 0, consing each element.

#### Scenario: non-empty vector
- **WHEN** `(vector->list (vector 1 2 3))` is evaluated
- **THEN** the result SHALL be `(1 2 3)`

#### Scenario: empty vector
- **WHEN** `(vector->list (vector))` is evaluated
- **THEN** the result SHALL be `()`

### Requirement: list->vector implemented in ECE
`list->vector` SHALL be implemented in `prelude.scm` by counting list length, allocating with `make-vector`, and filling with `vector-set!`.

#### Scenario: non-empty list
- **WHEN** `(list->vector '(1 2 3))` is evaluated
- **THEN** the result SHALL be a vector containing 1, 2, 3

#### Scenario: empty list
- **WHEN** `(list->vector '())` is evaluated
- **THEN** the result SHALL be an empty vector

### Requirement: all hosts remove dispatch for migrated primitives
Both CL and WASM primitive dispatch SHALL NOT handle IDs 33, 34, 35, 45, 46, 55, 56 after migration. WAT internal functions (`$prim-string-eq`, `$prim-string-lt`, `$prim-string-gt`, `$prim-list-to-vector`) MAY remain for internal callers.

#### Scenario: string=? works on CL after removal
- **WHEN** `(string=? "a" "a")` is evaluated on the CL runtime
- **THEN** the result SHALL be `#t` (provided by prelude.scm)

#### Scenario: vector->list works on WASM after removal
- **WHEN** `(vector->list (vector 1 2))` is evaluated on the WASM runtime
- **THEN** the result SHALL be `(1 2)` (provided by prelude.scm)
