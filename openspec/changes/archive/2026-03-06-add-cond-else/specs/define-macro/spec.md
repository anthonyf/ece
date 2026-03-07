## MODIFIED Requirements

### Requirement: cond derived form is available
The evaluator SHALL provide `cond` as a macro that expands to nested `if` expressions. Each clause SHALL support multiple body expressions, which are wrapped in `begin`. A clause with the test `else` SHALL be treated as always-true. A clause with the test `t` SHALL also work as a catch-all since `t` is self-evaluating and truthy.

#### Scenario: First true clause
- **WHEN** evaluating `(cond ((= 1 1) 10) ((= 2 3) 20))`
- **THEN** the result SHALL be `10`

#### Scenario: Second clause matches
- **WHEN** evaluating `(cond ((= 1 2) 10) ((= 2 2) 20))`
- **THEN** the result SHALL be `20`

#### Scenario: No clause matches returns nil
- **WHEN** evaluating `(cond ((= 1 2) 10) ((= 3 4) 20))`
- **THEN** the result SHALL be `nil`

#### Scenario: Multi-expression clause body
- **WHEN** evaluating `(begin (define x 0) (cond ((= 1 1) (set x 10) (+ x 5))) x)`
- **THEN** the result SHALL be `10`

#### Scenario: else clause as catch-all
- **WHEN** evaluating `(cond ((= 1 2) 10) (else 99))`
- **THEN** the result SHALL be `99`

#### Scenario: t clause as catch-all
- **WHEN** evaluating `(cond ((= 1 2) 10) (t 99))`
- **THEN** the result SHALL be `99`
