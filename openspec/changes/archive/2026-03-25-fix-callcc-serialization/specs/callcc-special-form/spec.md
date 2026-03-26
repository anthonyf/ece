## MODIFIED Requirements

### Requirement: call/cc skips wrapper when no dynamic-winds are active
When `*winding-stack*` is empty, `call/cc` SHALL delegate directly to `%raw-call/cc` without creating a wrapper lambda.

#### Scenario: call/cc continuation serializes and invokes without dynamic-wind
- **GIVEN** no active `dynamic-wind` forms
- **WHEN** a `call/cc` continuation is saved and loaded
- **THEN** `(continuation? loaded-k)` SHALL be `#t`
- **AND** invoking `(loaded-k value)` SHALL resume execution at the capture point

#### Scenario: call/cc still supports dynamic-wind
- **GIVEN** an active `dynamic-wind` with before/after thunks
- **WHEN** a `call/cc` continuation is captured and invoked
- **THEN** the before/after thunks SHALL execute in the correct order

#### Scenario: call/cc continuation round-trip
- **GIVEN** `(define r (call/cc (lambda (k) (save-continuation! "f" k) "first")))`
- **WHEN** `(define lk (load-continuation "f"))` then `(lk "second")`
- **THEN** `r` SHALL be `"second"` on the resumed pass
