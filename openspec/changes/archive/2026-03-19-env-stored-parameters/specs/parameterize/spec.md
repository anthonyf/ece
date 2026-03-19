## MODIFIED Requirements

### Requirement: parameterize works with env-stored parameters
`parameterize` SHALL provide dynamic rebinding of env-stored parameters with the same semantics as before.

#### Scenario: Dynamic rebinding
- **WHEN** `(parameterize ((p 99)) (p))` is evaluated
- **THEN** the result SHALL be `99`
- **AND** after the `parameterize` exits, `(p)` SHALL return the original value

#### Scenario: Dynamic scope visible to called functions
- **GIVEN** `(define (read-p) (p))`
- **WHEN** `(parameterize ((p 99)) (read-p))` is evaluated
- **THEN** the result SHALL be `99` (dynamic binding visible through the call)
