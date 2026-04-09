## MODIFIED Requirements

### Requirement: Tail calls in let/let* body execute in constant stack space
The compiler SHALL compile `let` and `let*` bodies in tail position with `'return` linkage, ensuring tail calls within the body do not grow the stack. The environment frame created by the `let`/`let*` SHALL be abandoned (not restored) when a tail call occurs.

#### Scenario: Tail call in let body
- **WHEN** evaluating `(begin (define (loop-let n) (let ((m (- n 1))) (if (= m 0) (quote done) (loop-let m)))) (loop-let 1000000))`
- **THEN** the result SHALL be `done`

#### Scenario: Tail call in let* body
- **WHEN** evaluating `(begin (define (loop-let* n) (let* ((m (- n 1)) (k m)) (if (= k 0) (quote done) (loop-let* k)))) (loop-let* 1000000))`
- **THEN** the result SHALL be `done`

#### Scenario: Nested let* in tail position
- **WHEN** evaluating `(begin (define (loop n) (let* ((a (- n 1))) (let* ((b a)) (if (= b 0) (quote done) (loop b))))) (loop 1000000))`
- **THEN** the result SHALL be `done`

#### Scenario: let in non-tail position does not break subsequent tail call
- **WHEN** evaluating `(begin (define (loop n) (let ((x n)) x) (if (= n 0) (quote done) (loop (- n 1)))) (loop 1000000))`
- **THEN** the result SHALL be `done`, confirming env restoration after non-tail let does not interfere with the subsequent tail call
