## ADDED Requirements

### Requirement: memq searches a list using eq?
The evaluator SHALL provide `memq` that returns the tail of the list starting from the first element matching the given value using `eq?`, or `#f` if not found.

#### Scenario: Symbol found
- **WHEN** evaluating `(memq 'c '(a b c d))`
- **THEN** the result SHALL be `(c d)`

#### Scenario: Symbol not found
- **WHEN** evaluating `(memq 'z '(a b c d))`
- **THEN** the result SHALL be `#f`

#### Scenario: Empty list
- **WHEN** evaluating `(memq 'a '())`
- **THEN** the result SHALL be `#f`

#### Scenario: Uses eq? not equal?
- **WHEN** evaluating `(memq '(a) '((a) (b)))`
- **THEN** the result SHALL be `#f` because `eq?` compares identity, not structure

### Requirement: assq searches an association list using eq?
The evaluator SHALL provide `assq` that searches an association list for a pair whose car matches the given key using `eq?`, or `#f` if not found.

#### Scenario: Key found
- **WHEN** evaluating `(assq 'b '((a 1) (b 2) (c 3)))`
- **THEN** the result SHALL be `(b 2)`

#### Scenario: Key not found
- **WHEN** evaluating `(assq 'd '((a 1) (b 2) (c 3)))`
- **THEN** the result SHALL be `#f`

#### Scenario: Empty alist
- **WHEN** evaluating `(assq 'a '())`
- **THEN** the result SHALL be `#f`

#### Scenario: Uses eq? not equal?
- **WHEN** evaluating `(assq '(a) '(((a) 1) ((b) 2)))`
- **THEN** the result SHALL be `#f` because `eq?` compares identity, not structure
