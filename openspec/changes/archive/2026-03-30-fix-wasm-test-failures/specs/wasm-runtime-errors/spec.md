## MODIFIED Requirements

### Requirement: subtraction preserves float type
WASM `$fold-sub` SHALL return a float when any operand is a float, including the first operand.

#### Scenario: float minus fixnum
- **WHEN** `(- 3.5 3)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `0.5` (float), not `0` (truncated integer)

#### Scenario: fixnum minus fixnum
- **WHEN** `(- 10 3)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `7` (fixnum)

### Requirement: wrap-f64 does not trap on large floats
WASM `$wrap-f64` SHALL NOT trap when the f64 value exceeds i32 range. It SHALL return a float-boxed value for any f64 that is outside fixnum range.

#### Scenario: large float wrapping
- **WHEN** `$wrap-f64` receives a value like `1e15`
- **THEN** it SHALL return a `$float-box` without trapping

#### Scenario: integer-valued float in fixnum range
- **WHEN** `$wrap-f64` receives `42.0`
- **THEN** it SHALL return a fixnum `42`
