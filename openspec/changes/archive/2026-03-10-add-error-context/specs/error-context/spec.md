## ADDED Requirements

### Requirement: runtime errors include ECE context
When a CL error occurs during `execute-instructions`, ECE SHALL catch it and signal an `ece-runtime-error` condition that includes the original error, current procedure, arguments, environment bindings, current instruction, and a backtrace.

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
When a CL error occurs during `execute-instructions`, ECE SHALL extract a call stack from the register machine's stack and include it in the error.

#### Scenario: Nested call shows backtrace
- **WHEN** an ECE program executes `(define (g) (+ 1 "bad"))` and `(define (f) (g))` and then `(f)`
- **THEN** the error message SHALL show a backtrace containing both `g` and `f`

#### Scenario: Backtrace is limited to 10 frames
- **WHEN** a deeply recursive ECE program errors
- **THEN** the backtrace SHALL show at most 10 frames

### Requirement: error context has zero overhead on success
The error context mechanism SHALL NOT measurably affect performance of programs that execute without errors.

#### Scenario: Normal execution is not slowed
- **WHEN** a program that executes 100,000 iterations runs with error context enabled
- **THEN** the execution time SHALL be within 5% of execution without error context

### Requirement: ece-runtime-error is a proper CL condition
`ece-runtime-error` SHALL be a CL condition class (subclass of `error`) with slot accessors for all context fields, allowing programmatic inspection by CL code.

#### Scenario: Condition slots are accessible
- **WHEN** an `ece-runtime-error` is caught via `handler-case`
- **THEN** `ece-original-error`, `ece-error-procedure`, `ece-error-arguments`, `ece-error-environment`, `ece-error-instruction`, and `ece-error-backtrace` SHALL return the respective values

### Requirement: error handler is robust against corrupt state
If the error context handler itself fails (e.g., due to corrupt environment data), it SHALL fall back to signaling the original unadorned CL error rather than masking it with a secondary error.

#### Scenario: Handler failure falls back to original error
- **WHEN** a runtime error occurs and the environment is corrupted such that formatting the context fails
- **THEN** the original CL error SHALL propagate unchanged
