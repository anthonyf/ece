## MODIFIED Requirements

### Requirement: current port accessors
`current-input-port` SHALL be a parameter object (as produced by `make-parameter`) whose value is the current default input port. `current-output-port` SHALL be a parameter object whose value is the current default output port. Called with no arguments, each SHALL return the current value. Called with one argument, each SHALL set the value. Called with two arguments (a value and a flag), each SHALL set the value without invoking any converter (supporting the R7RS `parameterize` restore semantics). Initial values SHALL wrap the host's standard input and standard output streams respectively, established once at boot via the `%initial-input-port` / `%initial-output-port` primitives.

#### Scenario: current-input-port returns stdin port
- **WHEN** `(current-input-port)` is called at startup
- **THEN** the result SHALL be an input port connected to standard input

#### Scenario: current-output-port returns stdout port
- **WHEN** `(current-output-port)` is called at startup
- **THEN** the result SHALL be an output port connected to standard output

#### Scenario: current-output-port is rebindable via parameterize
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(parameterize ((current-output-port p)) (display "hi")) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hi"`
- **AND** `(current-output-port)` AFTER the parameterize SHALL equal its value BEFORE the parameterize

#### Scenario: current-output-port is a procedure (parameter object)
- **WHEN** `(procedure? current-output-port)` is evaluated
- **THEN** the result SHALL be true

## ADDED Requirements

### Requirement: port-parameterized write primitives
The kernel SHALL expose low-level primitives that write to an explicitly-supplied port: `%display-to-port`, `%write-to-port`, `%newline-to-port`, `%write-char-to-port`, `%write-string-to-port`. These primitives SHALL require a port argument and SHALL NOT fall back to any host stream or ambient port.

#### Scenario: %display-to-port writes to the supplied port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(%display-to-port "hello" p)` then `(get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hello"`

#### Scenario: %newline-to-port writes a newline to the supplied port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(%display-to-port "x" p) (%newline-to-port p) (%display-to-port "y" p)` is evaluated, then `(get-output-string p)`
- **THEN** the final result SHALL be `"x\ny"`

### Requirement: display/write/newline default to current-output-port
`display`, `write`, `newline`, `write-char`, `write-string` SHALL be ECE procedures that accept an optional port argument. When called with no port argument, each SHALL write to `(current-output-port)`. When called with an explicit port, each SHALL write to that port.

#### Scenario: display with no port writes to current-output-port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(parameterize ((current-output-port p)) (display "hi")) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hi"`

#### Scenario: display with explicit port writes to that port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(display "hi" p) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hi"`

#### Scenario: write respects explicit port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(write "hi" p) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"\"hi\""` (with the string's escape-visible quotes)

#### Scenario: newline with no port writes to current-output-port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(parameterize ((current-output-port p)) (display "x") (newline) (display "y")) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"x\ny"`

## REMOVED Requirements

### Requirement: host current-port defvar aliasing
**Reason**: The `*current-output-port*` and `*current-input-port*` CL defvars in `runtime.lisp` were never consulted by `display` / `write` / `newline` / `write-char` / `write-string` — those primitives wrote directly to `*standard-output*`, making the defvars effectively dead code. Their role is replaced by ECE-side `make-parameter` instances whose values flow through `parameterize`.

**Migration**: Any CL-side caller that relied on the (never-functional) defvar aliasing has no migration path because the behavior never worked. Callers that want to capture ECE output from CL should call into ECE code that uses `with-output-to-string`, or use `(with-output-to-string (*standard-output*) ...)` on the CL side — the initial port still wraps CL's `*standard-output*`, so CL-level stream rebinding continues to work at boot.
