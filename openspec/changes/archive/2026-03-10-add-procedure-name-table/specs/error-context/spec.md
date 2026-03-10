## MODIFIED Requirements

### Requirement: runtime errors include ECE context
When a CL error occurs during `execute-instructions`, ECE SHALL catch it and signal an `ece-runtime-error` condition that includes the original error, current procedure, arguments, environment bindings, current instruction, and a backtrace. When the current procedure is a compiled procedure with a name in `*procedure-name-table*`, the error message SHALL display the procedure name.

#### Scenario: Unbound variable error includes procedure context
- **WHEN** an ECE program calls `(define (f x) (+ x y))` and then `(f 5)` where `y` is unbound
- **THEN** the error message SHALL include the procedure name `f` and the argument `(5)`

#### Scenario: Error includes visible bindings
- **WHEN** an ECE program calls `((lambda (x) (+ x y)) 5)` where `y` is unbound
- **THEN** the error message SHALL show the binding `x = 5` from the current environment

#### Scenario: Error includes the original error message
- **WHEN** any runtime error occurs
- **THEN** the `ece-runtime-error` condition SHALL contain the original CL error accessible via `ece-original-error`

### Requirement: runtime errors include a backtrace
When a CL error occurs during `execute-instructions`, ECE SHALL extract a call stack from the register machine's stack and include it in the error. Backtrace frames for compiled procedures SHALL display procedure names from `*procedure-name-table*` when available.

#### Scenario: Nested call shows backtrace
- **WHEN** an ECE program executes `(define (g) (+ 1 "bad"))` and `(define (f) (g))` and then `(f)`
- **THEN** the error message SHALL show a backtrace containing both `g` and `f`

#### Scenario: Backtrace is limited to 10 frames
- **WHEN** a deeply recursive ECE program errors
- **THEN** the backtrace SHALL show at most 10 frames
