## MODIFIED Requirements

### Requirement: Loaded continuation is invokable
A continuation saved with `save-continuation!` and loaded with `load-continuation` SHALL be invokable — calling it resumes execution at the capture point.

#### Scenario: Simple save and invoke
- **GIVEN** `(call/cc (lambda (k) (save-continuation! "/tmp/k.dat" k) 'first))`
- **WHEN** `(define loaded-k (load-continuation "/tmp/k.dat"))` then `(loaded-k 'resumed)`
- **THEN** execution SHALL resume at the `call/cc` capture point with value `'resumed`

#### Scenario: Continuation preserves lexical state
- **GIVEN** a continuation captured inside a `let` with mutable parameters
- **WHEN** the continuation is saved, state is mutated, then the continuation is loaded and invoked
- **THEN** execution SHALL resume with the state as it was at save time

#### Scenario: continuation? recognizes loaded continuations
- **GIVEN** a continuation saved and loaded
- **WHEN** `(continuation? loaded-k)` is called
- **THEN** the result SHALL be `#t`
