## ADDED Requirements

### Requirement: Undefined variable lookup signals an error
When `lookup-variable-value` fails to find a variable in the environment chain, the runtime SHALL signal a clear error including the variable name, instead of silently returning null.

#### Scenario: Undefined variable in user code
- **WHEN** user code references an undefined variable `foo`
- **THEN** a runtime error is raised with message "Unbound variable: foo"

### Requirement: Symbol table grows when full
The symbol interning function SHALL grow the symbol name and ref arrays when the symbol count reaches capacity, instead of writing out of bounds.

#### Scenario: Program interns more symbols than initial capacity
- **WHEN** a program creates more unique symbols than the initial array capacity
- **THEN** the arrays are doubled in size and interning continues without error

### Requirement: Space array grows when full
The space registration function SHALL grow the spaces array when a space ID exceeds the current array length, instead of writing out of bounds.

#### Scenario: Space ID exceeds initial array size
- **WHEN** a compilation space is registered with a symbol ID greater than the current spaces array length
- **THEN** the array is grown to accommodate the ID and registration succeeds

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
