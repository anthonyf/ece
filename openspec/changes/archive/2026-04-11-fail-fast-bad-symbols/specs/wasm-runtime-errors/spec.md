## MODIFIED Requirements

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
