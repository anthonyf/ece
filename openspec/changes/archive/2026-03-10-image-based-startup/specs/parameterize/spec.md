## MODIFIED Requirements

### Requirement: make-parameter creates parameter objects
`make-parameter` SHALL create a parameter object — a procedure that returns its current value when called with zero arguments and sets it when called with one argument. Parameter objects SHALL use a serializable parameter table instead of CL `symbol-function` closures, so they survive image save/load round-trips.

#### Scenario: Create and read parameter
- **WHEN** `(define p (make-parameter 42))` is evaluated
- **THEN** `(p)` SHALL return `42`

#### Scenario: Set parameter value
- **WHEN** `(p 99)` is called on a parameter `p` with current value `42`
- **THEN** `(p)` SHALL return `99` afterward

#### Scenario: Parameter with converter
- **WHEN** `(define p (make-parameter "hello" string-length))` is evaluated
- **THEN** `(p)` SHALL return `5` (converter applied to initial value)

#### Scenario: Converter applied on set
- **WHEN** a parameter with converter `string-length` has `(p "world")` called
- **THEN** `(p)` SHALL return `5`

#### Scenario: Parameter survives image round-trip
- **WHEN** a parameter is created with `(make-parameter 42)` and an image is saved and loaded
- **THEN** the parameter SHALL still return `42` when called with zero arguments
- **AND** setting the parameter SHALL work correctly after load
