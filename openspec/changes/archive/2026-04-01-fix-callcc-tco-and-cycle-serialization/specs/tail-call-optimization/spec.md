## MODIFIED Requirements

### Requirement: Tail calls in if consequent and alternative execute in constant stack space
The evaluator SHALL execute a call in the consequent or alternative position of `if` without growing the continuation stack, enabling unbounded tail recursion.

#### Scenario: Tail call in if alternative
- **WHEN** evaluating `(begin (define (loop-if n) (if (= n 0) (quote done) (loop-if (- n 1)))) (loop-if 1000000))`
- **THEN** the result SHALL be `done`

#### Scenario: Tail call in if alternative with call/cc
- **WHEN** evaluating `(begin (define (loop n) (if (= n 0) (quote done) (call/cc (lambda (k) (loop (- n 1)))))) (loop 1000000))`
- **THEN** the result SHALL be `done` without stack overflow
