## ADDED Requirements

### Requirement: dynamic-wind executes before, thunk, and after in order
`dynamic-wind` SHALL accept three zero-argument thunks (`before`, `thunk`, `after`) and execute them in order: `before`, then `thunk`, then `after`. It SHALL return the value of `thunk`.

#### Scenario: Basic before/thunk/after ordering
- **WHEN** `(let ((log '())) (dynamic-wind (lambda () (set! log (cons 'before log))) (lambda () (set! log (cons 'thunk log)) 42) (lambda () (set! log (cons 'after log)))) log)` is evaluated
- **THEN** the return value of `dynamic-wind` SHALL be `42`
- **AND** `log` SHALL be `(after thunk before)`

#### Scenario: Nested dynamic-wind
- **WHEN** two `dynamic-wind` forms are nested
- **THEN** the outer `before` runs first, then inner `before`, then body, then inner `after`, then outer `after`

### Requirement: Winding stack tracks active dynamic extents
The system SHALL maintain a `*winding-stack*` that records the current chain of active `(before . after)` pairs from innermost to outermost.

#### Scenario: Winding stack grows and shrinks
- **WHEN** `dynamic-wind` is entered, the `(before . after)` pair is pushed onto `*winding-stack*`
- **THEN** when `dynamic-wind` returns normally, the pair is popped from `*winding-stack*`

### Requirement: Continuation exit triggers after thunks
When a continuation captured outside a `dynamic-wind` is invoked from inside, the `after` thunks of exited extents SHALL be called.

#### Scenario: call/cc escape triggers after
- **WHEN** `(call/cc (lambda (k) (dynamic-wind (lambda () 'before) (lambda () (k 'escaped)) (lambda () (set! log 'after-ran))))) log` is evaluated
- **THEN** the result SHALL be `escaped`
- **AND** `log` SHALL be `after-ran`

#### Scenario: Multiple levels unwind on escape
- **WHEN** a continuation escapes through two nested `dynamic-wind` forms
- **THEN** the inner `after` runs first, then the outer `after`

### Requirement: Continuation re-entry triggers before thunks
When a continuation captured inside a `dynamic-wind` is invoked from outside, the `before` thunks of entered extents SHALL be called.

#### Scenario: Re-entering a dynamic-wind extent
- **WHEN** a continuation is captured inside a `dynamic-wind` and later invoked from outside
- **THEN** the `before` thunk SHALL be called before execution resumes at the capture point

### Requirement: do-winds! computes minimal unwind/rewind path
`do-winds!` SHALL compute the common tail between the current winding stack and the target winding stack, call `after` thunks for extents being left (innermost first), then call `before` thunks for extents being entered (outermost first).

#### Scenario: No winding needed when stacks are identical
- **WHEN** `do-winds!` is called with the current stack equal to the target stack
- **THEN** no `before` or `after` thunks are called

#### Scenario: Full unwind and rewind across different extents
- **WHEN** a continuation crosses from one `dynamic-wind` extent to a different one
- **THEN** the exited extent's `after` runs, then the entered extent's `before` runs

### Requirement: %raw-call/cc available as escape hatch
`%raw-call/cc` SHALL be available as a special form that captures raw continuations without winding awareness, for internal use by the prelude and performance-critical code.

#### Scenario: %raw-call/cc captures without winding
- **WHEN** `(%raw-call/cc (lambda (k) (k 42)))` is evaluated inside a `dynamic-wind`
- **THEN** the result SHALL be `42`
- **AND** no `after` thunk SHALL be triggered by invoking the raw continuation
