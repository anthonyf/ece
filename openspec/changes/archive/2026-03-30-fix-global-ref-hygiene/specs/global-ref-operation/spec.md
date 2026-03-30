## ADDED Requirements

### Requirement: lookup-global-variable operation
A new register machine operation `lookup-global-variable` SHALL be available that looks up a variable by name in the global environment only, bypassing all lexical frames. It SHALL take one argument (the variable name) and return the value bound in the global environment.

#### Scenario: global lookup bypasses lexical shadow
- **WHEN** `+` is bound to `*` in a lexical frame and `lookup-global-variable` is called with `+`
- **THEN** the result SHALL be the global `+` (addition), not the local `*` (multiplication)

#### Scenario: unbound variable in global env
- **WHEN** `lookup-global-variable` is called with a name not bound in the global environment
- **THEN** an "Unbound variable" error SHALL be signaled

### Requirement: compiler emits lookup-global-variable for %global-ref
The compiler's `mc-compile-global-ref` SHALL emit `(assign target (op lookup-global-variable) (const name))` instead of `(assign target (op lookup-variable-value) (const name) (reg env))`.

#### Scenario: compiled %global-ref instruction
- **WHEN** `(%global-ref +)` is compiled
- **THEN** the generated instruction SHALL use the `lookup-global-variable` operation with no env argument

### Requirement: operation implemented on all runtimes
`lookup-global-variable` SHALL be implemented in both the CL runtime (`runtime.lisp`) and the WASM runtime (`runtime.wat`). Op-id SHALL be 23.

#### Scenario: CL implementation
- **WHEN** the CL executor encounters op-id 23
- **THEN** it SHALL call `lookup-variable-value` with `*global-env*`

#### Scenario: WASM implementation
- **WHEN** the WASM executor encounters op-id 23
- **THEN** it SHALL call `$lookup-variable-value` with `$global-env`
