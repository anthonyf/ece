## Requirements

### Requirement: Named let provides local iteration
The evaluator SHALL support named `let` syntax: `(let name ((var init) ...) body ...)`. This SHALL define a local function `name` bound to `(lambda (var ...) body ...)` and immediately call it with the `init` values. The loop name SHALL be callable recursively from within the body.

#### Scenario: Simple counting loop
- **WHEN** evaluating `(let loop ((i 0) (sum 0)) (if (= i 5) sum (loop (+ i 1) (+ sum i))))`
- **THEN** the result SHALL be `10`

#### Scenario: Named let with tail recursion
- **WHEN** evaluating `(let loop ((n 1000000)) (if (= n 0) (quote done) (loop (- n 1))))`
- **THEN** the result SHALL be `done`

#### Scenario: Building a list with named let
- **WHEN** evaluating `(let loop ((i 3) (acc (quote ()))) (if (= i 0) acc (loop (- i 1) (cons i acc))))`
- **THEN** the result SHALL be `(1 2 3)`

#### Scenario: Regular let still works
- **WHEN** evaluating `(let ((x 10) (y 20)) (+ x y))`
- **THEN** the result SHALL be `30`
