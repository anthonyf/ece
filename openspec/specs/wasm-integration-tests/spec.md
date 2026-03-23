## ADDED Requirements

### Requirement: Yield/resume integration test
The WASM test runner SHALL test the full yield/resume cycle from JS: eval a program that calls `(yield)`, verify a continuation is stored, resume via `call_ece_proc`, and verify output.

#### Scenario: Single yield and resume
- **WHEN** a program `(begin (define (f) (display "A") (yield) (display "B")) (f))` is evaluated via `eval-string` and then resumed via `call_ece_proc`
- **THEN** the output after eval is "A", and after resume is "AB"

#### Scenario: Multi-frame yield/resume
- **WHEN** a game-loop-style program yields 3 times and JS resumes each time via `call_ece_proc`
- **THEN** each frame produces incremented output and `hasYieldCont` returns true between frames

### Requirement: All portable ECE tests run on WASM
All ECE test files that do not require CL-specific features (try-eval, save-continuation) SHALL be included in the WASM test suite.

#### Scenario: call/cc tests on WASM
- **WHEN** `make test-wasm` runs
- **THEN** test-callcc.scm and test-advanced-continuations.scm are included and pass

#### Scenario: dynamic-wind tests on WASM
- **WHEN** `make test-wasm` runs
- **THEN** test-dynamic-wind.scm is included and passes

#### Scenario: guard and eval-string tests on WASM
- **WHEN** `make test-wasm` runs
- **THEN** test-guard.scm and test-eval-string.scm are included and pass
