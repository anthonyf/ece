## ADDED Requirements

### Requirement: string->number parses integers
`string->number` SHALL be implemented in `prelude.scm` as a character-by-character parser using `string-ref`, `char->integer`, and arithmetic. It SHALL return the parsed integer for valid integer strings.

#### Scenario: positive integer
- **WHEN** `(string->number "42")` is evaluated
- **THEN** the result SHALL be `42`

#### Scenario: negative integer
- **WHEN** `(string->number "-7")` is evaluated
- **THEN** the result SHALL be `-7`

#### Scenario: explicit positive sign
- **WHEN** `(string->number "+5")` is evaluated
- **THEN** the result SHALL be `5`

#### Scenario: zero
- **WHEN** `(string->number "0")` is evaluated
- **THEN** the result SHALL be `0`

### Requirement: string->number parses decimal floats
`string->number` SHALL parse decimal numbers containing a `.` and return a numeric value with fractional part.

#### Scenario: decimal float
- **WHEN** `(string->number "3.14")` is evaluated
- **THEN** the result SHALL be `3.14`

#### Scenario: negative float
- **WHEN** `(string->number "-0.5")` is evaluated
- **THEN** the result SHALL be `-0.5`

#### Scenario: leading dot
- **WHEN** `(string->number ".5")` is evaluated
- **THEN** the result SHALL be `0.5`

#### Scenario: trailing dot
- **WHEN** `(string->number "42.")` is evaluated
- **THEN** the result SHALL be `42.0` (a float, not integer)

### Requirement: string->number returns #f for invalid input
`string->number` SHALL return `#f` for any string that is not a valid number.

#### Scenario: empty string
- **WHEN** `(string->number "")` is evaluated
- **THEN** the result SHALL be `#f`

#### Scenario: non-numeric string
- **WHEN** `(string->number "hello")` is evaluated
- **THEN** the result SHALL be `#f`

#### Scenario: sign only
- **WHEN** `(string->number "-")` is evaluated
- **THEN** the result SHALL be `#f`

#### Scenario: dot only
- **WHEN** `(string->number ".")` is evaluated
- **THEN** the result SHALL be `#f`

#### Scenario: embedded non-digit
- **WHEN** `(string->number "12x4")` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: all hosts remove dispatch for migrated primitives
Both CL and WASM primitive dispatch SHALL NOT handle IDs 19 (`boolean?`) and 29 (`string->number`) after migration. WAT internal function `$is-boolean` MAY remain for internal callers. WAT functions `$prim-string-to-number` and `$parse-float-after-dot` SHALL be removed (no internal callers).

#### Scenario: string->number works on CL after removal
- **WHEN** `(string->number "42")` is evaluated on the CL runtime
- **THEN** the result SHALL be `42` (provided by prelude.scm)

#### Scenario: boolean? works on WASM after removal
- **WHEN** `(boolean? #t)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `#t` (provided by prelude.scm)
