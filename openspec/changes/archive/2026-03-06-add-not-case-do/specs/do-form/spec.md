## ADDED Requirements

### Requirement: do provides general iteration
The evaluator SHALL provide `do` as a macro for general iteration. Each variable binding SHALL have an initial value and an optional step expression. The termination test SHALL be checked before each iteration. When the test is true, the result expressions SHALL be evaluated and the last one returned. When the test is false, the body SHALL be evaluated and variables stepped.

#### Scenario: Simple counting loop
- **WHEN** evaluating `(do ((i 0 (+ i 1))) ((= i 5) i))`
- **THEN** the result SHALL be `5`

#### Scenario: Accumulating loop
- **WHEN** evaluating `(do ((i 0 (+ i 1)) (sum 0 (+ sum i))) ((= i 5) sum))`
- **THEN** the result SHALL be `10`

#### Scenario: Loop with body for side effects
- **WHEN** evaluating `(begin (define result (quote ())) (do ((i 0 (+ i 1))) ((= i 3) result) (set result (cons i result))))`
- **THEN** the result SHALL be `(2 1 0)`

#### Scenario: Variable without step expression stays constant
- **WHEN** evaluating `(do ((x 10) (i 0 (+ i 1))) ((= i 3) x))`
- **THEN** the result SHALL be `10`

#### Scenario: Immediate termination
- **WHEN** evaluating `(do ((i 0 (+ i 1))) ((= i 0) 'done))`
- **THEN** the result SHALL be `done`
