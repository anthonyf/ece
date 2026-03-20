## NEW Requirements

### Requirement: parameters are tagged values in the environment
`make-parameter` SHALL return `(parameter (<value> . <converter>))` stored directly in the ECE environment.

#### Scenario: Create and read
- **WHEN** `(define p (make-parameter 42))` then `(p)` is called
- **THEN** the result SHALL be `42`

#### Scenario: Set and read
- **WHEN** `(p 99)` then `(p)` is called
- **THEN** the result SHALL be `99`
- **AND** `(p 99)` SHALL return the old value `42`

#### Scenario: Converter on init
- **WHEN** `(define p (make-parameter "hello" string-length))`
- **THEN** `(p)` SHALL return `5` (converter applied to initial value)

#### Scenario: Converter on set
- **WHEN** `(p "world")` is called on a parameter with `string-length` converter
- **THEN** `(p)` SHALL return `5` (converter applied to new value)

#### Scenario: Raw set (2 args, bypass converter)
- **WHEN** `(p 99 #t)` is called
- **THEN** the value SHALL be set to `99` without applying the converter

### Requirement: parameters are callable as procedures
Parameters SHALL be callable with the same syntax as procedures: `(p)` for get, `(p val)` for set.

#### Scenario: Procedure call dispatch
- **WHEN** a parameter is in the `proc` register during a procedure application
- **THEN** the executor SHALL dispatch to the parameter branch
- **AND** handle 0-arg (get), 1-arg (set with converter), and 2-arg (raw set) cases

### Requirement: parameters serialize with continuations
Parameter values SHALL be captured in serialized continuations automatically.

#### Scenario: Parameter round-trip
- **GIVEN** `(define p (make-parameter 42))` then `(p 99)` then a continuation is captured
- **WHEN** the continuation is serialized and deserialized
- **THEN** `(p)` on the deserialized parameter SHALL return `99`

### Requirement: no CL-side parameter table
The CL-side `*parameter-table*` and `*parameter-counter*` SHALL be removed. All parameter state SHALL live in the ECE environment.
