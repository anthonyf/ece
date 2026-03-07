## ADDED Requirements

### Requirement: letrec provides recursive local bindings
The evaluator SHALL support `letrec` as a macro: `(letrec ((var init) ...) body ...)`. All variables SHALL be visible in all init expressions and the body, enabling recursive and mutually recursive definitions.

#### Scenario: Single recursive binding
- **WHEN** evaluating `(letrec ((fact (lambda (n) (if (= n 0) 1 (* n (fact (- n 1))))))) (fact 5))`
- **THEN** the result SHALL be `120`

#### Scenario: Mutually recursive bindings
- **WHEN** evaluating `(letrec ((even? (lambda (n) (if (= n 0) (quote t) (odd? (- n 1))))) (odd? (lambda (n) (if (= n 0) (quote ()) (even? (- n 1)))))) (even? 10))`
- **THEN** the result SHALL be `t`

#### Scenario: Mutually recursive bindings (odd case)
- **WHEN** evaluating `(letrec ((even? (lambda (n) (if (= n 0) (quote t) (odd? (- n 1))))) (odd? (lambda (n) (if (= n 0) (quote ()) (even? (- n 1)))))) (odd? 7))`
- **THEN** the result SHALL be `t`

#### Scenario: Body in tail position
- **WHEN** evaluating `(letrec ((loop (lambda (n) (if (= n 0) (quote done) (loop (- n 1)))))) (loop 1000000))`
- **THEN** the result SHALL be `done`
