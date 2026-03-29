## ADDED Requirements

### Requirement: char-whitespace? implemented in ECE
The `char-whitespace?` primitive SHALL be implemented in prelude.scm as range checks on `char->integer`. It SHALL return `#t` for space (32), tab (9), newline (10), and carriage return (13).

#### Scenario: whitespace characters detected
- **WHEN** `(char-whitespace? #\space)` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: non-whitespace rejected
- **WHEN** `(char-whitespace? #\A)` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: char-alphabetic? implemented in ECE
The `char-alphabetic?` primitive SHALL be implemented in prelude.scm as range checks on `char->integer`. It SHALL return `#t` for A-Z (65-90) and a-z (97-122).

#### Scenario: alphabetic characters detected
- **WHEN** `(char-alphabetic? #\a)` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: non-alphabetic rejected
- **WHEN** `(char-alphabetic? #\5)` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: char-numeric? implemented in ECE
The `char-numeric?` primitive SHALL be implemented in prelude.scm as range checks on `char->integer`. It SHALL return `#t` for 0-9 (48-57).

#### Scenario: numeric characters detected
- **WHEN** `(char-numeric? #\5)` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: non-numeric rejected
- **WHEN** `(char-numeric? #\a)` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: equal? implemented in ECE
The `equal?` primitive SHALL be implemented in prelude.scm as recursive structural equality. It SHALL use `eq?` for identity, recurse on `pair?` and `vector?`, use `string=?` for strings, and use `=` for numbers.

#### Scenario: pair equality
- **WHEN** `(equal? '(1 2 3) '(1 2 3))` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: vector equality
- **WHEN** `(equal? (vector 1 2) (vector 1 2))` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: identity shortcut
- **WHEN** `(let ((x '(1 2))) (equal? x x))` is evaluated
- **THEN** the result SHALL be `#t`

### Requirement: eqv? implemented in ECE
The `eqv?` primitive SHALL be implemented in prelude.scm. It SHALL return `#t` if `eq?` returns `#t`, or if both arguments are numbers and `=` returns `#t`.

#### Scenario: numeric equivalence
- **WHEN** `(eqv? 42 42)` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: non-eq non-numeric
- **WHEN** `(eqv? "hello" "hello")` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: gensym implemented in ECE
The `gensym` primitive SHALL be implemented in prelude.scm using a counter variable, `number->string`, `string-append`, and `string->symbol`. Each call SHALL produce a unique interned symbol.

#### Scenario: unique symbols
- **WHEN** `(eq? (gensym) (gensym))` is evaluated
- **THEN** the result SHALL be `#f`

#### Scenario: symbol type
- **WHEN** `(symbol? (gensym))` is evaluated
- **THEN** the result SHALL be `#t`

### Requirement: CL host removes string primitives
The CL host runtime SHALL NOT implement `string-downcase` (36), `string-upcase` (37), `string-split` (38), `string-trim` (39), `string-contains?` (40), `string-join` (41), or `print` (66) as host primitives. These SHALL be provided by prelude.scm.

#### Scenario: string-downcase works after CL removal
- **WHEN** `(string-downcase "HELLO")` is evaluated on the CL runtime
- **THEN** the result SHALL be `"hello"` (provided by prelude.scm)

### Requirement: both hosts remove migrated primitives
For each migrated primitive, the corresponding host dispatch entry SHALL be removed from both `runtime.lisp` (CL) and `runtime.wat` (WASM) after the ECE implementation is verified.

#### Scenario: char-whitespace? not in WASM dispatch
- **WHEN** the WASM `apply-primitive` function receives primitive ID 47
- **THEN** it SHALL NOT have a host-level handler (the ECE prelude provides the implementation)

#### Scenario: modulo not in CL dispatch
- **WHEN** the CL primitive dispatch table is built
- **THEN** ID 4 (`modulo`) SHALL NOT have a host-level handler (the ECE prelude provides the implementation)

#### Scenario: modulo not in WASM dispatch
- **WHEN** the WASM `apply-primitive` function receives primitive ID 4
- **THEN** it SHALL NOT have a host-level handler (the ECE prelude provides the implementation)

### Requirement: primitives.def updated
Migrated primitives SHALL have their platform annotation changed from `core` to `ece` in `primitives.def` to document that they are now prelude-level. Additionally, new core primitives `truncate` (108) and `floor` (109) SHALL be added.

#### Scenario: annotation reflects migration
- **WHEN** `primitives.def` is read
- **THEN** `char-whitespace?` (47), `char-alphabetic?` (48), `char-numeric?` (49), `equal?` (21), `eqv?` (174), `gensym` (82), `string-downcase` (36), `string-upcase` (37), `string-split` (38), `string-trim` (39), `string-contains?` (40), `string-join` (41), `print` (66), and `modulo` (4) SHALL have platform `ece`

#### Scenario: new core primitives registered
- **WHEN** `primitives.def` is read
- **THEN** `truncate` (108) and `floor` (109) SHALL have platform `core`
