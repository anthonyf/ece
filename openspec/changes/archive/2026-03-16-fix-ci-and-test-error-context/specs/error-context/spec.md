## MODIFIED Requirements

### Requirement: runtime errors include ECE context
When a CL error occurs during `execute-instructions`, ECE SHALL catch it and signal an `ece-runtime-error` condition that includes the original error, current procedure, arguments, environment bindings, current instruction, and a backtrace. When the current procedure is a compiled procedure with a name in `*procedure-name-table*`, the error message SHALL display the procedure name.

Environment bindings captured in the error SHALL reflect the runtime frame representation. For compiler-generated frames (vector-based), the environment SHALL contain the frame values. Variable names are a compile-time concept and are not required to be present in captured environments.

#### Scenario: Unbound variable error includes procedure context
- **WHEN** an ECE program calls `(define (f x) (+ x y))` and then `(f 5)` where `y` is unbound
- **THEN** the error message SHALL include the procedure name `f` and the argument `(5)`

#### Scenario: Error includes visible bindings
- **WHEN** an ECE program calls `((lambda (x) (+ x y)) 5)` where `y` is unbound
- **THEN** the `ece-error-environment` SHALL contain a non-empty environment where the innermost frame contains the value `5`

#### Scenario: Error includes the original error message
- **WHEN** any runtime error occurs
- **THEN** the `ece-runtime-error` condition SHALL contain the original CL error accessible via `ece-original-error`
