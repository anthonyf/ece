## MODIFIED Requirements

### Requirement: or derived form is available
The evaluator SHALL provide `or` as a macro. `or` SHALL return the first truthy value, or the last value if none are truthy. Each argument SHALL be evaluated at most once.

#### Scenario: First truthy
- **WHEN** evaluating `(or (quote ()) 2 3)`
- **THEN** the result SHALL be `2`

#### Scenario: All falsy
- **WHEN** evaluating `(or (quote ()) (quote ()))`
- **THEN** the result SHALL be `nil`

#### Scenario: Empty or
- **WHEN** evaluating `(or)`
- **THEN** the result SHALL be `nil`

#### Scenario: No double evaluation of truthy argument
- **WHEN** evaluating `(begin (define counter 0) (or (begin (set counter (+ counter 1)) counter) 99) counter)`
- **THEN** the result SHALL be `1`
