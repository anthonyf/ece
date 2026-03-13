## ADDED Requirements

### Requirement: Arithmetic primitives type-check their arguments
`+`, `-`, `*`, `/`, `=`, `<`, `>`, `mod`, `abs`, `min`, `max` SHALL verify all arguments are numbers before calling the underlying CL function. On type mismatch, they SHALL call ECE `error` with a descriptive message and the offending value as an irritant.

#### Scenario: Addition with non-number signals ECE error
- **WHEN** evaluating `(+ "a" 1)`
- **THEN** an ECE error-object SHALL be raised with message containing "not a number"

#### Scenario: Addition with valid numbers succeeds
- **WHEN** evaluating `(+ 1 2 3)`
- **THEN** the result SHALL be `6`

#### Scenario: Division by zero signals ECE error
- **WHEN** evaluating `(/ 1 0)`
- **THEN** an ECE error-object SHALL be raised with message containing "division by zero"

#### Scenario: Comparison with non-number signals ECE error
- **WHEN** evaluating `(< "a" 1)`
- **THEN** an ECE error-object SHALL be raised with message containing "not a number"

### Requirement: List access primitives type-check their arguments
`car` and `cdr` SHALL verify their argument is a pair before calling the underlying CL function. On type mismatch, they SHALL call ECE `error`.

#### Scenario: car of non-pair signals ECE error
- **WHEN** evaluating `(car 5)`
- **THEN** an ECE error-object SHALL be raised with message containing "not a pair"

#### Scenario: cdr of non-pair signals ECE error
- **WHEN** evaluating `(cdr "hello")`
- **THEN** an ECE error-object SHALL be raised with message containing "not a pair"

#### Scenario: car of valid pair succeeds
- **WHEN** evaluating `(car '(1 2))`
- **THEN** the result SHALL be `1`

### Requirement: String comparison primitives type-check their arguments
`string=?`, `string<?`, `string>?` SHALL verify all arguments are strings. On type mismatch, they SHALL call ECE `error`.

#### Scenario: string=? with non-string signals ECE error
- **WHEN** evaluating `(string=? 42 "hello")`
- **THEN** an ECE error-object SHALL be raised with message containing "not a string"

### Requirement: Char primitives type-check their arguments
`char=?`, `char<?`, `char->integer`, `integer->char` SHALL verify argument types. On type mismatch, they SHALL call ECE `error`.

#### Scenario: char=? with non-char signals ECE error
- **WHEN** evaluating `(char=? 1 2)`
- **THEN** an ECE error-object SHALL be raised with message containing "not a character"

#### Scenario: integer->char with non-integer signals ECE error
- **WHEN** evaluating `(integer->char "a")`
- **THEN** an ECE error-object SHALL be raised with message containing "not an integer"

### Requirement: Vector access primitives type-check their arguments
`vector-ref` and `vector-length` SHALL verify their first argument is a vector. `vector-ref` SHALL also verify the index is a valid non-negative integer within bounds.

#### Scenario: vector-ref with non-vector signals ECE error
- **WHEN** evaluating `(vector-ref 42 0)`
- **THEN** an ECE error-object SHALL be raised with message containing "not a vector"

#### Scenario: vector-ref with out-of-bounds index signals ECE error
- **WHEN** evaluating `(vector-ref #(1 2 3) 5)`
- **THEN** an ECE error-object SHALL be raised with message containing "out of bounds"

### Requirement: Bitwise primitives type-check their arguments
`bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift` SHALL verify all arguments are integers. On type mismatch, they SHALL call ECE `error`.

#### Scenario: bitwise-and with non-integer signals ECE error
- **WHEN** evaluating `(bitwise-and "a" 1)`
- **THEN** an ECE error-object SHALL be raised with message containing "not an integer"

### Requirement: Type errors from safe primitives are catchable by guard
All type errors raised by safe primitive wrappers SHALL be catchable by `guard` since they use ECE's `error`/`raise` mechanism.

#### Scenario: guard catches arithmetic type error
- **WHEN** evaluating `(guard (e (#t (error-object-message e))) (+ "a" 1))`
- **THEN** the result SHALL be a string containing "not a number"

#### Scenario: guard catches car type error
- **WHEN** evaluating `(guard (e (#t (error-object-message e))) (car 5))`
- **THEN** the result SHALL be a string containing "not a pair"

#### Scenario: guard catches division by zero
- **WHEN** evaluating `(guard (e (#t (error-object-message e))) (/ 1 0))`
- **THEN** the result SHALL be a string containing "division by zero"

### Requirement: Raw primitives remain accessible via %raw- prefix
All renamed primitives SHALL be accessible via their `%raw-` prefixed name for internal use and performance-critical code.

#### Scenario: %raw-+ is available
- **WHEN** evaluating `(%raw-+ 1 2)`
- **THEN** the result SHALL be `3`

#### Scenario: %raw-car is available
- **WHEN** evaluating `(%raw-car '(1 2))`
- **THEN** the result SHALL be `1`
