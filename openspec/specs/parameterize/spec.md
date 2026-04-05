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

### Requirement: parameterize rebinds current-output-port across procedure calls
`parameterize` SHALL correctly rebind `current-output-port` such that `display`, `write`, `newline`, `write-char`, and `write-string` calls within its dynamic extent — including calls inside procedures invoked from within the body — write to the rebound port.

#### Scenario: Nested procedure call writes to rebound port
- **GIVEN** `(define (greet) (display "hello"))` and `(define p (open-output-string))`
- **WHEN** `(parameterize ((current-output-port p)) (greet)) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hello"`

#### Scenario: Outer port restored after body exits
- **GIVEN** the original `(current-output-port)` value `P0`
- **WHEN** `(parameterize ((current-output-port (open-output-string))) (display "ignored"))` returns
- **THEN** `(current-output-port)` SHALL be `eq?` to `P0`

### Requirement: parameterize restores port when body raises
When the body of `parameterize` exits non-locally (via `raise`, captured continuation invoked outside the body, or uncaught error caught further out), `current-output-port` SHALL be restored to its prior value before control reaches any outer handler.

#### Scenario: guard-caught error inside body restores port
- **GIVEN** the original `(current-output-port)` value `P0`
- **WHEN** `(guard (e (#t 'caught)) (parameterize ((current-output-port (open-output-string))) (raise 'boom)))` is evaluated
- **THEN** the result SHALL be `caught`
- **AND** `(current-output-port)` after the guard form SHALL be `eq?` to `P0`

#### Scenario: Continuation escape out of parameterize restores port
- **GIVEN** the original `(current-output-port)` value `P0`
- **WHEN** `(call/cc (lambda (k) (parameterize ((current-output-port (open-output-string))) (k 'done))))` is evaluated
- **THEN** the result SHALL be `done`
- **AND** `(current-output-port)` after the `call/cc` SHALL be `eq?` to `P0`
