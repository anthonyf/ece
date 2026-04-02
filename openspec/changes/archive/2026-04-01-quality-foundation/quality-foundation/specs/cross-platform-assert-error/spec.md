## ADDED Requirements

### Requirement: assert-error works on all platforms
The `assert-error` macro SHALL use `guard` for error catching instead of `try-eval`, making it available on both CL and WASM platforms.

#### Scenario: Expression that errors passes on CL
- **WHEN** `(assert-error (/ 1 0))` is evaluated on CL
- **THEN** the assertion passes because the expression signaled an error

#### Scenario: Expression that errors passes on WASM
- **WHEN** `(assert-error (error "boom"))` is evaluated on WASM
- **THEN** the assertion passes because the expression signaled an error

#### Scenario: Expression that succeeds fails
- **WHEN** `(assert-error (+ 1 2))` is evaluated on any platform
- **THEN** the assertion fails because no error was signaled

### Requirement: assert-error-message works on all platforms
The `assert-error-message` macro SHALL continue to use `guard` (as it already does) and SHALL work identically on both platforms.

#### Scenario: Matching error message on WASM
- **WHEN** `(assert-error-message (error "expected") "expected")` is evaluated on WASM
- **THEN** the assertion passes and the pass count increments

### Requirement: Error test files run on both platforms
`test-errors.scm` and `test-error-messages.scm` SHALL run on both CL and WASM without being excluded from the test manifest.

#### Scenario: test-errors.scm on WASM
- **WHEN** `test-errors.scm` is loaded and executed on WASM
- **THEN** all tests using the new `assert-error` SHALL execute and produce pass/fail results
