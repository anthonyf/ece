## MODIFIED Requirements

### Requirement: call/cc produces raw serializable continuations
`call/cc` SHALL produce raw continuations (not wrapper lambdas). Winding transitions SHALL be handled at invocation time by the executor.

#### Scenario: call/cc continuation is a continuation (not compiled-procedure)
- **WHEN** `(call/cc (lambda (k) (continuation? k)))`
- **THEN** the result SHALL be `#t`

#### Scenario: call/cc continuation serializes and invokes
- **GIVEN** `(define r (call/cc (lambda (k) (serialize! k port) "first")))`
- **WHEN** `(define lk (deserialize port))` then `(lk "second")`
- **THEN** `r` SHALL be `"second"` on the resumed pass

#### Scenario: call/cc still runs dynamic-wind after thunks on escape
- **GIVEN** `(call/cc (lambda (k) (dynamic-wind before (lambda () (k 'escaped)) after)))`
- **THEN** `after` SHALL be called before resuming at the capture point

#### Scenario: call/cc continuation invoked from inside dynamic-wind runs after thunks
- **GIVEN** a continuation captured outside dynamic-wind, invoked from inside
- **THEN** the after thunks SHALL execute (unwinding to the captured winding state)

#### Scenario: serialized continuation preserves winding behavior
- **GIVEN** a continuation serialized and deserialized
- **WHEN** invoked from inside a dynamic-wind
- **THEN** winding transitions SHALL execute correctly
