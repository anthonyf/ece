## ADDED Requirements

### Requirement: number->string implemented in ECE
The `number->string` primitive SHALL be implemented in `prelude.scm` using `quotient`, `modulo`, `integer->char`, `string`, and `string-append`. It SHALL convert an integer to its decimal string representation.

#### Scenario: zero
- **WHEN** `(number->string 0)` is evaluated
- **THEN** the result SHALL be `"0"`

#### Scenario: positive single digit
- **WHEN** `(number->string 7)` is evaluated
- **THEN** the result SHALL be `"7"`

#### Scenario: positive multi-digit
- **WHEN** `(number->string 42)` is evaluated
- **THEN** the result SHALL be `"42"`

#### Scenario: negative number
- **WHEN** `(number->string -13)` is evaluated
- **THEN** the result SHALL be `"-13"`

#### Scenario: large number
- **WHEN** `(number->string 1000000)` is evaluated
- **THEN** the result SHALL be `"1000000"`

### Requirement: number->string defined before gensym in prelude
The `number->string` definition SHALL appear after `quotient`/`modulo` and before `gensym` in `prelude.scm`, respecting the dependency chain: `quotient` → `number->string` → `gensym`.

#### Scenario: gensym works after migration
- **WHEN** `(symbol? (gensym))` is evaluated
- **THEN** the result SHALL be `#t`

### Requirement: CL host removes number->string
The CL host runtime SHALL NOT implement `number->string` (ID 30) as a host primitive. The `ece-number->string` function and its entry in `*wrapper-primitives*` SHALL be removed from `runtime.lisp`.

#### Scenario: number->string works on CL after removal
- **WHEN** `(number->string 42)` is evaluated on the CL runtime
- **THEN** the result SHALL be `"42"` (provided by prelude.scm)

### Requirement: WASM removes number->string from primitive dispatch
The WASM `$apply-primitive` function SHALL NOT dispatch primitive ID 30. The `$prim-number-to-string` WAT function MAY remain as an internal helper for `$write-to-string-impl` and `$display-to-port`.

#### Scenario: number->string works on WASM after dispatch removal
- **WHEN** `(number->string 42)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `"42"` (provided by prelude.scm via the compiled procedure)
