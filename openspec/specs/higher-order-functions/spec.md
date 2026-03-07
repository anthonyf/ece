## Requirements

### Requirement: filter selects elements matching a predicate
The evaluator SHALL provide `filter` as a built-in procedure that takes a predicate and a list, returning a new list of elements for which the predicate returns true. The implementation SHALL be tail-recursive and SHALL not grow the stack proportionally to list length.

#### Scenario: filter even numbers
- **WHEN** evaluating `(filter even? (quote (1 2 3 4 5 6)))`
- **THEN** the result SHALL be `(2 4 6)`

#### Scenario: filter with no matches
- **WHEN** evaluating `(filter even? (quote (1 3 5)))`
- **THEN** the result SHALL be `()`

#### Scenario: filter empty list
- **WHEN** evaluating `(filter even? (quote ()))`
- **THEN** the result SHALL be `()`

#### Scenario: filter with lambda
- **WHEN** evaluating `(filter (lambda (x) (> x 3)) (quote (1 2 3 4 5)))`
- **THEN** the result SHALL be `(4 5)`

#### Scenario: filter large list without stack overflow
- **WHEN** evaluating `(filter even? <list of 100000 elements>)`
- **THEN** the result SHALL complete without stack overflow

### Requirement: reduce folds a list with a function and initial value
The evaluator SHALL provide `reduce` as a built-in procedure that takes a binary function, an initial accumulator value, and a list, and returns the result of folding left over the list.

#### Scenario: reduce sum
- **WHEN** evaluating `(reduce + 0 (quote (1 2 3 4 5)))`
- **THEN** the result SHALL be `15`

#### Scenario: reduce with empty list
- **WHEN** evaluating `(reduce + 0 (quote ()))`
- **THEN** the result SHALL be `0`

#### Scenario: reduce building a list (cons in reverse)
- **WHEN** evaluating `(reduce (lambda (acc x) (cons x acc)) (quote ()) (quote (1 2 3)))`
- **THEN** the result SHALL be `(3 2 1)`

### Requirement: for-each applies a procedure for side effects
The evaluator SHALL provide `for-each` as a built-in procedure that takes a procedure and a list, applies the procedure to each element for side effects, and returns nil.

#### Scenario: for-each with display
- **WHEN** evaluating `(begin (for-each display (quote (1 2 3))) (quote done))`
- **THEN** `1`, `2`, and `3` SHALL be displayed and the result SHALL be `done`

#### Scenario: for-each returns nil
- **WHEN** evaluating `(for-each (lambda (x) x) (quote (1 2 3)))`
- **THEN** the result SHALL be `()`
