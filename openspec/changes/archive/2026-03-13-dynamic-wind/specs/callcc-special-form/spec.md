## MODIFIED Requirements

### Requirement: call/cc captures and restores continuation
`call/cc` SHALL be a macro that expands to `%raw-call/cc` with a winding-aware continuation wrapper. The wrapped continuation SHALL call `do-winds!` before invoking the raw continuation, ensuring `dynamic-wind` `before`/`after` thunks fire on continuation jumps. `%raw-call/cc` SHALL be the special form that captures the raw continuation (stack and program counter state) and passes it to the receiver function. Invoking the raw continuation SHALL restore the captured state and return the given value.

#### Scenario: Simple capture and invoke
- **WHEN** `(call/cc (lambda (k) (k 42)))` is evaluated
- **THEN** the result SHALL be `42`

#### Scenario: Continuation as escape
- **WHEN** `(call/cc (lambda (k) (begin (k 10) 20)))` is evaluated
- **THEN** the result SHALL be `10` (the expression after `k` is never reached)

#### Scenario: Continuation works with compiled procedures
- **WHEN** `(let ((x 5)) (call/cc (lambda (k) (k x))))` is evaluated
- **THEN** the result SHALL be `5`
- **AND** the continuation SHALL capture the compiled execution state (stack and instruction pointer)

#### Scenario: Saved continuation can be invoked later
- **WHEN** a continuation is stored in a variable and invoked after `call/cc` returns
- **THEN** execution SHALL resume from the point of capture with the given value

#### Scenario: call/cc respects dynamic-wind
- **WHEN** `call/cc` captures a continuation inside a `dynamic-wind` and it is invoked from outside
- **THEN** the `before` thunk SHALL be called on re-entry and `after` SHALL be called on exit
