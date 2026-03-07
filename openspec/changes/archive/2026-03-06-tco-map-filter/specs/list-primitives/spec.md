## MODIFIED Requirements

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
