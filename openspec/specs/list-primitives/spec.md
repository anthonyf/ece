## Requirements

### Requirement: List access shortcuts are available
The evaluator SHALL provide `cadr`, `caddr`, `caar`, and `cddr` as primitive procedures.

#### Scenario: cadr returns second element
- **WHEN** evaluating `(cadr (quote (1 2 3)))`
- **THEN** the result SHALL be `2`

#### Scenario: caddr returns third element
- **WHEN** evaluating `(caddr (quote (1 2 3)))`
- **THEN** the result SHALL be `3`

#### Scenario: caar returns car of car
- **WHEN** evaluating `(caar (quote ((a b) c)))`
- **THEN** the result SHALL be `a`

#### Scenario: cddr returns cdr of cdr
- **WHEN** evaluating `(cddr (quote (1 2 3)))`
- **THEN** the result SHALL be `(3)`

### Requirement: append combines lists
The evaluator SHALL provide `append` as a primitive that concatenates lists.

#### Scenario: Append two lists
- **WHEN** evaluating `(append (quote (1 2)) (quote (3 4)))`
- **THEN** the result SHALL be `(1 2 3 4)`

#### Scenario: Append empty list
- **WHEN** evaluating `(append (quote ()) (quote (1 2)))`
- **THEN** the result SHALL be `(1 2)`

### Requirement: length returns list length
The evaluator SHALL provide `length` as a primitive.

#### Scenario: Length of a list
- **WHEN** evaluating `(length (quote (a b c)))`
- **THEN** the result SHALL be `3`

#### Scenario: Length of empty list
- **WHEN** evaluating `(length (quote ()))`
- **THEN** the result SHALL be `0`

### Requirement: pair? tests for cons cells
The evaluator SHALL provide `pair?` which returns true for cons cells and false otherwise.

#### Scenario: Cons cell is a pair
- **WHEN** evaluating `(pair? (cons 1 2))`
- **THEN** the result SHALL be true

#### Scenario: Number is not a pair
- **WHEN** evaluating `(pair? 42)`
- **THEN** the result SHALL be false

#### Scenario: Empty list is not a pair
- **WHEN** evaluating `(pair? (quote ()))`
- **THEN** the result SHALL be false

### Requirement: map applies a function to each element
The evaluator SHALL provide `map` that applies a function to each element of a list, returning a new list of results. The implementation SHALL be tail-recursive and SHALL not grow the stack proportionally to list length.

#### Scenario: Map with lambda
- **WHEN** evaluating `(map (lambda (x) (+ x 1)) (quote (1 2 3)))`
- **THEN** the result SHALL be `(2 3 4)`

#### Scenario: Map with primitive
- **WHEN** evaluating `(map car (quote ((1 2) (3 4) (5 6))))`
- **THEN** the result SHALL be `(1 3 5)`

#### Scenario: Map over empty list
- **WHEN** evaluating `(map (lambda (x) x) (quote ()))`
- **THEN** the result SHALL be `()`

#### Scenario: Map large list without stack overflow
- **WHEN** evaluating `(map (lambda (x) (+ x 1)) <list of 100000 elements>)`
- **THEN** the result SHALL complete without stack overflow

### Requirement: apply calls a procedure with a list of arguments
The evaluator SHALL provide `apply` that calls a procedure with arguments from a list.

#### Scenario: Apply primitive with argument list
- **WHEN** evaluating `(apply + (quote (1 2 3)))`
- **THEN** the result SHALL be `6`

#### Scenario: Apply lambda with argument list
- **WHEN** evaluating `(apply (lambda (x y) (+ x y)) (quote (3 4)))`
- **THEN** the result SHALL be `7`

#### Scenario: Apply named ECE function
- **WHEN** evaluating `(begin (define (add a b) (+ a b)) (apply add (quote (10 20))))`
- **THEN** the result SHALL be `30`
