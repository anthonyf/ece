## ADDED Requirements

### Requirement: raise invokes the current exception handler
`raise` SHALL invoke the current exception handler with the given object. If no handler is installed, it SHALL fall through to the CL error system.

#### Scenario: raise with handler installed
- **WHEN** `(with-exception-handler (lambda (e) e) (lambda () (raise 'boom)))` is evaluated
- **THEN** the handler receives `boom` as its argument

#### Scenario: raise with no handler falls through to CL
- **WHEN** `(raise 'unhandled)` is evaluated with no exception handler installed
- **THEN** a CL-level error SHALL be signaled

### Requirement: with-exception-handler installs a handler for the dynamic extent of a thunk
`with-exception-handler` SHALL install `handler` as the current exception handler for the dynamic extent of `thunk`. It SHALL use `dynamic-wind` to properly manage handler installation and removal, so that continuation jumps correctly maintain the handler stack.

#### Scenario: Handler catches raised exception
- **WHEN** an exception is raised inside `thunk`
- **THEN** the installed `handler` is invoked with the exception object

#### Scenario: Handler is removed after thunk completes
- **WHEN** `thunk` completes normally
- **THEN** the handler is no longer active for subsequent code

#### Scenario: Nested handlers
- **WHEN** two `with-exception-handler` forms are nested and the inner handler raises
- **THEN** the outer handler catches the re-raised exception

### Requirement: error creates an error object and raises it
`error` SHALL accept a message string and zero or more irritant values, construct an `error-object` record, and call `raise` on it.

#### Scenario: error with message only
- **WHEN** `(guard (e (#t (error-object-message e))) (error "bad input"))` is evaluated
- **THEN** the result SHALL be `"bad input"`

#### Scenario: error with message and irritants
- **WHEN** `(guard (e (#t (error-object-irritants e))) (error "index out of range" 5 10))` is evaluated
- **THEN** the result SHALL be `(5 10)`

### Requirement: error-object record type
`error-object` SHALL be a record type with `message` and `irritants` fields.

#### Scenario: error-object? predicate
- **WHEN** an error is caught via `guard`
- **THEN** `(error-object? e)` SHALL return `#t`

#### Scenario: error-object-message accessor
- **WHEN** `(error-object-message (make-error-object "msg" '()))` is evaluated
- **THEN** the result SHALL be `"msg"`

#### Scenario: error-object-irritants accessor
- **WHEN** `(error-object-irritants (make-error-object "msg" '(1 2)))` is evaluated
- **THEN** the result SHALL be `(1 2)`

#### Scenario: Non-error-object fails predicate
- **WHEN** `(error-object? 42)` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: guard macro for cond-style exception handling
`guard` SHALL evaluate its body with an exception handler. When an exception is raised, the exception object is bound to the specified variable and the clauses are evaluated as `cond` clauses in the continuation of the `guard` expression.

#### Scenario: Basic guard catches error
- **WHEN** `(guard (e (#t 'caught)) (error "fail"))` is evaluated
- **THEN** the result SHALL be `caught`

#### Scenario: Guard with matching clause
- **WHEN** `(guard (e ((error-object? e) (error-object-message e))) (error "hello"))` is evaluated
- **THEN** the result SHALL be `"hello"`

#### Scenario: Guard with multiple clauses
- **WHEN** `(guard (e ((string? e) 'string) ((number? e) 'number) (else 'other)) (raise 42))` is evaluated
- **THEN** the result SHALL be `number`

#### Scenario: Guard with else clause
- **WHEN** `(guard (e (else 'default)) (raise 'anything))` is evaluated
- **THEN** the result SHALL be `default`

#### Scenario: Guard re-raises when no clause matches
- **WHEN** `(guard (outer (else 'outer-caught)) (guard (inner ((number? inner) 'num)) (raise "not-a-number")))` is evaluated
- **THEN** the result SHALL be `outer-caught` because the inner guard re-raises

#### Scenario: Guard body returns normally
- **WHEN** `(guard (e (#t 'error)) (+ 1 2))` is evaluated
- **THEN** the result SHALL be `3` (no exception, body value returned)

#### Scenario: Nested guard
- **WHEN** two `guard` forms are nested and the inner body raises
- **THEN** the inner `guard`'s clauses are evaluated first

### Requirement: call-with-current-continuation function
`call-with-current-continuation` SHALL be a first-class function equivalent to the `call/cc` macro, for use in contexts where a procedure value is needed.

#### Scenario: call-with-current-continuation as procedure
- **WHEN** `(call-with-current-continuation (lambda (k) (k 99)))` is evaluated
- **THEN** the result SHALL be `99`

#### Scenario: Respects dynamic-wind
- **WHEN** `call-with-current-continuation` captures a continuation inside `dynamic-wind` and it is later invoked from outside
- **THEN** the `before`/`after` thunks SHALL fire correctly
