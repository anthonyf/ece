## ADDED Requirements

### Requirement: eval is callable from ECE code
ECE SHALL provide an `eval` procedure that compiles and executes an expression at runtime, returning the result.

#### Scenario: Evaluate a literal
- **WHEN** `(eval 42)` is called
- **THEN** the result SHALL be `42`

#### Scenario: Evaluate an arithmetic expression
- **WHEN** `(eval '(+ 1 2))` is called
- **THEN** the result SHALL be `3`

#### Scenario: Evaluate a definition
- **WHEN** `(eval '(define eval-test-var 99))` is called followed by `eval-test-var`
- **THEN** the variable SHALL be bound to `99` in the global environment

#### Scenario: Evaluate a lambda and call it
- **WHEN** `(eval '(begin (define (eval-test-fn x) (* x x)) (eval-test-fn 5)))` is called
- **THEN** the result SHALL be `25`
