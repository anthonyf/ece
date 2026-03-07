## MODIFIED Requirements

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
