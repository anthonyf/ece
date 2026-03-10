## ADDED Requirements

### Requirement: make-parameter creates parameter objects
`make-parameter` SHALL create a parameter object — a procedure that returns its current value when called with zero arguments and sets it when called with one argument.

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

### Requirement: parameterize dynamically rebinds parameters
`parameterize` SHALL dynamically rebind parameter objects for the extent of its body, restoring original values afterward. Called functions within the body SHALL see the rebound values.

#### Scenario: Basic dynamic rebinding
- **WHEN** `(parameterize ((p 99)) (p))` is evaluated where `p` has value `42`
- **THEN** the result SHALL be `99`
- **AND** `(p)` SHALL be `42` after `parameterize` returns

#### Scenario: Dynamic scope propagates to called functions
- **WHEN** a function `(define (read-p) (p))` is called inside `(parameterize ((p 99)) (read-p))`
- **THEN** `read-p` SHALL return `99`

#### Scenario: Multiple bindings
- **WHEN** `(parameterize ((p1 10) (p2 20)) (+ (p1) (p2)))` is evaluated
- **THEN** the result SHALL be `30`

#### Scenario: Nested parameterize
- **WHEN** `(parameterize ((p 1)) (parameterize ((p 2)) (p)))` is evaluated
- **THEN** the result SHALL be `2`
- **AND** `(p)` SHALL be the original value after both return

#### Scenario: Converter applied during parameterize
- **WHEN** a parameter with converter is rebound via `parameterize`
- **THEN** the converter SHALL be applied to the new value
