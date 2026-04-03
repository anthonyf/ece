## ADDED Requirements

### Requirement: Casting car/cdr helpers
The WASM runtime SHALL provide `$xcar` and `$xcdr` functions that accept `(ref null eq)`, cast to `$pair`, and return the car/cdr field as `(ref null eq)`.

#### Scenario: xcar extracts car from untyped reference
- **WHEN** `$xcar` is called with a value that is a `$pair`
- **THEN** it SHALL return the car field of that pair

#### Scenario: xcdr extracts cdr from untyped reference
- **WHEN** `$xcdr` is called with a value that is a `$pair`
- **THEN** it SHALL return the cdr field of that pair

#### Scenario: xcar on non-pair traps
- **WHEN** `$xcar` is called with a value that is not a `$pair`
- **THEN** it SHALL trap (WASM ref.cast failure)

### Requirement: Composed list accessors
The WASM runtime SHALL provide `$cadr` and `$caddr` composed accessors.

#### Scenario: cadr returns second element
- **WHEN** `$cadr` is called with a list of at least 2 elements
- **THEN** it SHALL return the second element (car of cdr)

#### Scenario: caddr returns third element
- **WHEN** `$caddr` is called with a list of at least 3 elements
- **THEN** it SHALL return the third element (car of cdr of cdr)

### Requirement: All casting call sites use helpers
Every `(call $car (ref.cast (ref $pair) ...))` pattern in runtime.wat SHALL be replaced with `$xcar`, `$cadr`, or `$caddr` as appropriate. The `ref.cast (ref $pair)` pattern SHALL only appear in `$xcar`/`$xcdr` definitions and in code that genuinely needs a typed `$pair` reference (e.g., `$set-car!`).
