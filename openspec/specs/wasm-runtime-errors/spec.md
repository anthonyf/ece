## ADDED Requirements

### Requirement: Undefined variable lookup signals an error
When `lookup-variable-value` or `lookup-global-variable` fail to find a variable in the environment chain, the runtime SHALL signal a catchable error with message `"Unbound variable: <name>"` where `<name>` is the symbol name that was looked up. The error SHALL surface at the lookup site (not later, when a null value is passed to another operation), and SHALL propagate through the existing error-sentinel bridge in the op dispatch so `guard` can catch it.

#### Scenario: Undefined variable in user code signals at lookup
- **WHEN** user code references an undefined variable `foo`
- **THEN** a runtime error SHALL be raised with message `"Unbound variable: foo"` at the lookup site, before any downstream operation attempts to use the lookup result

#### Scenario: Unbound variable error is catchable by guard
- **WHEN** `(guard (e ((error-object? e) (error-object-message e))) undefined-var)` is evaluated on the WASM runtime
- **THEN** the result SHALL be the string `"Unbound variable: undefined-var"`

#### Scenario: Unbound variable error is catchable by try-eval
- **WHEN** `(try-eval '(undefined-var))` is evaluated on the WASM runtime
- **THEN** the evaluation SHALL complete without crashing and return the EOF sentinel after printing the unbound-variable error

#### Scenario: Lookup does not return null to downstream ops
- **WHEN** an unbound variable lookup is followed by `(op compiled-procedure-entry)` on the same register
- **THEN** the op dispatch SHALL route the error sentinel through ECE's `error` function rather than reaching `compiled-procedure-entry` with a null value

#### Scenario: WASM and CL runtimes produce identical unbound-variable messages
- **WHEN** the same undefined-variable reference is evaluated on both the WASM and CL runtimes under `(guard (e ((error-object? e) (error-object-message e))) ...)`
- **THEN** both runtimes SHALL return the same `"Unbound variable: <name>"` string

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

### Requirement: %raw-error implemented on WASM
Primitive 81 (`%raw-error`) SHALL be implemented on the WASM runtime. It SHALL signal a fatal error by calling `$signal-error-str` with the error message, which throws a JS exception via the `runtime_error` import.

#### Scenario: %raw-error signals fatal error
- **WHEN** `(%raw-error "something failed")` is evaluated on WASM
- **THEN** a JS exception SHALL be thrown with the message "something failed"

### Requirement: division-by-zero catchable by guard
`quotient`, `modulo`, and `remainder` SHALL check for zero divisor and call ECE's `error` function (not a WAT-level error). This makes the error catchable by `guard` on all platforms.

#### Scenario: guard catches division by zero in modulo
- **WHEN** `(guard (e ((error-object? e) #t)) (modulo 10 0) #f)` is evaluated on WASM
- **THEN** the result SHALL be `#t`

#### Scenario: guard catches division by zero in quotient
- **WHEN** `(guard (e ((error-object? e) #t)) (quotient 10 0) #f)` is evaluated on WASM
- **THEN** the result SHALL be `#t`
