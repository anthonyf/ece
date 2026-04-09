## Requirements

### Requirement: Tail calls in if consequent and alternative execute in constant stack space
The evaluator SHALL execute a call in the consequent or alternative position of `if` without growing the continuation stack, enabling unbounded tail recursion.

#### Scenario: Tail call in if alternative
- **WHEN** evaluating `(begin (define (loop-if n) (if (= n 0) (quote done) (loop-if (- n 1)))) (loop-if 1000000))`
- **THEN** the result SHALL be `done`

#### Scenario: Tail call in if alternative with call/cc
- **WHEN** evaluating `(begin (define (loop n) (if (= n 0) (quote done) (call/cc (lambda (k) (loop (- n 1)))))) (loop 1000000))`
- **THEN** the result SHALL be `done` without stack overflow

### Requirement: Tail calls in begin last expression execute in constant stack space
The evaluator SHALL execute the last expression in a `begin` form in tail position.

#### Scenario: Tail call as last expression in begin
- **WHEN** evaluating `(begin (define (loop-begin n) (if (= n 0) (quote done) (begin (quote ignore) (loop-begin (- n 1))))) (loop-begin 1000000))`
- **THEN** the result SHALL be `done`

### Requirement: Tail calls in cond clause bodies execute in constant stack space
The evaluator SHALL execute calls in the tail position of `cond` clause bodies without growing the stack.

#### Scenario: Tail call in cond clause
- **WHEN** evaluating `(begin (define (loop-cond n) (cond ((= n 0) (quote done)) ((quote t) (loop-cond (- n 1))))) (loop-cond 1000000))`
- **THEN** the result SHALL be `done`

### Requirement: Tail calls in and/or last expression execute in constant stack space
The evaluator SHALL execute the last argument of `and` and `or` in tail position.

#### Scenario: Tail call as last argument of and
- **WHEN** evaluating `(begin (define (loop-and n) (if (= n 0) (quote done) (and (quote t) (loop-and (- n 1))))) (loop-and 1000000))`
- **THEN** the result SHALL be `done`

#### Scenario: Tail call as last argument of or
- **WHEN** evaluating `(begin (define (loop-or n) (if (= n 0) (quote done) (or (quote ()) (loop-or (- n 1))))) (loop-or 1000000))`
- **THEN** the result SHALL be `done`

### Requirement: Tail calls in when/unless body execute in constant stack space
The evaluator SHALL execute calls in the tail position of `when` and `unless` bodies without growing the stack.

#### Scenario: Tail call in when body
- **WHEN** evaluating `(begin (define (loop-when n) (when (> n 0) (loop-when (- n 1)))) (loop-when 1000000))`
- **THEN** the result SHALL be `nil`

#### Scenario: Tail call in unless body
- **WHEN** evaluating `(begin (define (loop-unless n) (unless (= n 0) (loop-unless (- n 1)))) (loop-unless 1000000))`
- **THEN** the result SHALL be `nil`

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

### Requirement: Tail calls via apply execute in constant stack space
The evaluator SHALL execute `(apply f args)` in tail position without growing the continuation stack, enabling unbounded tail recursion through apply.

#### Scenario: Tail call via apply
- **WHEN** evaluating `(begin (define (loop-apply n) (if (= n 0) (quote done) (apply loop-apply (list (- n 1))))) (loop-apply 1000000))`
- **THEN** the result SHALL be `done`
