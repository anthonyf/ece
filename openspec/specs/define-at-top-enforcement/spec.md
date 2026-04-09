## Requirements

### Requirement: Internal defines restricted to beginning of body
The compiler SHALL signal a compile-time error if an internal `define` form appears after any non-define expression in a lambda body, `let` body, or `begin` body within a lambda.

#### Scenario: Defines at top of body accepted
- **WHEN** compiling `(lambda () (define x 1) (define y 2) (+ x y))`
- **THEN** compilation SHALL succeed

#### Scenario: Define after expression rejected
- **WHEN** compiling `(lambda () (display "hi") (define x 1) x)`
- **THEN** the compiler SHALL signal an error indicating that `define` is not permitted after an expression in the body

#### Scenario: Define inside top-level begin accepted
- **WHEN** compiling `(lambda () (begin (define x 1) (define y 2)) (+ x y))`
- **THEN** compilation SHALL succeed, because `begin` at the top of a body is transparent (its contents are spliced)

#### Scenario: Define-macro at top of body accepted
- **WHEN** compiling `(lambda () (define-macro (m x) x) (define y 1) (m y))`
- **THEN** compilation SHALL succeed, because `define-macro` is treated like `define` for body-position purposes

#### Scenario: Nested lambda allows its own defines
- **WHEN** compiling `(lambda () (display "hi") (lambda () (define x 1) x))`
- **THEN** compilation SHALL succeed, because the inner lambda has its own body where `define` is at the top

#### Scenario: Define inside if rejected
- **WHEN** compiling `(lambda () (if #t (define x 1) (define x 2)) x)`
- **THEN** the compiler SHALL signal an error, because `define` inside `if` is not at the beginning of the body

### Requirement: Top-level defines unrestricted
The define-at-top restriction SHALL apply only to internal defines (inside lambda, let, or other body forms). Top-level `define` forms at the REPL or in a file SHALL remain unrestricted.

#### Scenario: Top-level defines in sequence
- **WHEN** compiling a file containing `(display "hello") (define x 1) (display x)`
- **THEN** compilation SHALL succeed, because these are top-level forms, not internal defines
