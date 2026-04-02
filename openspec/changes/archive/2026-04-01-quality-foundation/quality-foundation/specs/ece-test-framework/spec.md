## MODIFIED Requirements

### Requirement: assert-error check
The framework SHALL provide `assert-error` that verifies an expression signals an error. It SHALL use `guard` to catch errors, making it available on all platforms (CL and WASM).

#### Scenario: Expression that errors passes
- **WHEN** `(assert-error (/ 1 0))` is evaluated
- **THEN** the assertion passes because the expression signaled an error

#### Scenario: Expression that succeeds fails
- **WHEN** `(assert-error (+ 1 2))` is evaluated
- **THEN** the assertion fails because no error was signaled

### Requirement: Test execution with error isolation
`run-tests` SHALL execute all registered tests, wrapping each in `guard` so that one test failure or error does not abort the suite. This SHALL work on all platforms without depending on `try-eval`.

#### Scenario: One test errors, others continue
- **WHEN** three tests are registered and the second one signals an unhandled error
- **THEN** all three tests are executed, the second is marked as errored, and the first and third run normally

### Requirement: Tests use abstract predicates for internal types
Tests SHALL use `continuation?`, `compiled-procedure?`, and `primitive?` to test the type of internal values. Tests SHALL NOT use `pair?` / `car` to inspect the representation of continuations, compiled procedures, or primitives.

#### Scenario: Continuation type check is platform-independent
- **WHEN** a test verifies that a value captured by `call/cc` is a continuation
- **THEN** it SHALL use `(continuation? val)` rather than `(pair? val)` or `(eq? (car val) 'continuation)`

#### Scenario: Tests pass on both CL and WASM
- **WHEN** a test file using `(continuation? val)` is run on CL (where continuations are tagged lists) and WASM (where continuations are GC structs)
- **THEN** the test SHALL pass on both platforms
