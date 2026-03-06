## ADDED Requirements

### Requirement: call/cc captures the current continuation and passes it to the receiver
The evaluator SHALL support `(call/cc <receiver>)` where receiver is a one-argument procedure. The receiver SHALL be called with a continuation object representing the current continuation.

#### Scenario: Simple call/cc returns value from receiver
- **WHEN** evaluating `(call/cc (lambda (k) 42))`
- **THEN** the result SHALL be `42`

#### Scenario: Continuation used for non-local exit
- **WHEN** evaluating `(call/cc (lambda (k) (k 10) 20))`
- **THEN** the result SHALL be `10` (the `(k 10)` invokes the continuation, skipping `20`)

### Requirement: Continuations work within larger expressions
The continuation SHALL capture the full evaluation context so that invoking it resumes computation correctly.

#### Scenario: call/cc in arithmetic expression
- **WHEN** evaluating `(+ 1 (call/cc (lambda (k) (k 10))))`
- **THEN** the result SHALL be `11`

#### Scenario: call/cc with non-local exit in nested context
- **WHEN** evaluating `(+ 1 (call/cc (lambda (k) (+ 2 (k 10)))))`
- **THEN** the result SHALL be `11` (the `(k 10)` abandons `(+ 2 ...)` and returns 10 to the `(+ 1 ...)`)

### Requirement: Receiver expression is evaluated
The receiver argument to `call/cc` SHALL be an arbitrary expression that is evaluated before being applied.

#### Scenario: Variable as receiver
- **WHEN** evaluating `((lambda (f) (call/cc f)) (lambda (k) (k 99)))`
- **THEN** the result SHALL be `99`

### Requirement: Continuation not called returns receiver's result
When the receiver does not invoke the continuation, `call/cc` SHALL return the receiver's return value.

#### Scenario: Continuation ignored
- **WHEN** evaluating `(+ 1 (call/cc (lambda (k) 5)))`
- **THEN** the result SHALL be `6`
