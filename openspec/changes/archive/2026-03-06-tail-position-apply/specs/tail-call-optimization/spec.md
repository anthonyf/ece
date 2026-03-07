## ADDED Requirements

### Requirement: Tail calls via apply execute in constant stack space
The evaluator SHALL execute `(apply f args)` in tail position without growing the continuation stack, enabling unbounded tail recursion through apply.

#### Scenario: Tail call via apply
- **WHEN** evaluating `(begin (define (loop-apply n) (if (= n 0) (quote done) (apply loop-apply (list (- n 1))))) (loop-apply 1000000))`
- **THEN** the result SHALL be `done`
