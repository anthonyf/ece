## MODIFIED Requirements

### Requirement: error signals an error with a message
`error` SHALL accept a message string and zero or more irritant values, construct an `error-object` record, and call `raise`. When no ECE exception handler is installed, `raise` SHALL fall through to the CL error system, preserving the existing REPL/debugger experience.

#### Scenario: Signal an error
- **WHEN** evaluating `(error "something went wrong")`
- **THEN** an error SHALL be raised with an `error-object` whose message is `"something went wrong"` and irritants is `()`

#### Scenario: Signal an error with irritants
- **WHEN** evaluating `(error "bad value" 42 "extra")`
- **THEN** an error SHALL be raised with an `error-object` whose message is `"bad value"` and irritants is `(42 "extra")`

#### Scenario: Error is catchable by guard
- **WHEN** evaluating `(guard (e (#t (error-object-message e))) (error "oops"))`
- **THEN** the result SHALL be `"oops"`

#### Scenario: Error is catchable by try-eval
- **WHEN** evaluating `(try-eval '(error "oops"))`
- **THEN** the result SHALL be nil (error was caught, no crash)
