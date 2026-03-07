## ADDED Requirements

### Requirement: nested quasiquote preserves inner templates
The evaluator SHALL support nested `quasiquote` forms. An `unquote` inside an inner `quasiquote` SHALL NOT be evaluated at the outer level; it SHALL be preserved as literal `(unquote ...)` structure until the inner quasiquote is itself evaluated.

#### Scenario: Inner unquote preserved at depth 2
- **WHEN** evaluating `(begin (define x 1) (quasiquote (a (quasiquote (b (unquote x))))))`
- **THEN** the result SHALL be `(a (quasiquote (b (unquote x))))`

#### Scenario: Outer unquote evaluated, inner preserved
- **WHEN** evaluating `(begin (define x 1) (quasiquote (a (unquote x) (quasiquote (b (unquote x))))))`
- **THEN** the result SHALL be `(a 1 (quasiquote (b (unquote x))))`

#### Scenario: Nested unquote-splicing preserved at depth 2
- **WHEN** evaluating `(begin (define xs (quote (1 2))) (quasiquote (a (quasiquote (b (unquote-splicing xs))))))`
- **THEN** the result SHALL be `(a (quasiquote (b (unquote-splicing xs))))`
