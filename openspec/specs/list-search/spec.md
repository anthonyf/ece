## ADDED Requirements

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

### Requirement: assoc finds a pair by key in an association list
The evaluator SHALL provide `assoc` that searches an association list for a pair whose car matches the given key.

#### Scenario: Key found
- **WHEN** evaluating `(assoc 'b '((a 1) (b 2) (c 3)))`
- **THEN** the result SHALL be `(b 2)`

#### Scenario: Key not found
- **WHEN** evaluating `(assoc 'd '((a 1) (b 2) (c 3)))`
- **THEN** the result SHALL be false

#### Scenario: Numeric key
- **WHEN** evaluating `(assoc 2 '((1 a) (2 b) (3 c)))`
- **THEN** the result SHALL be `(2 b)`

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

### Requirement: member tests for list membership
The evaluator SHALL provide `member` that returns the tail of the list starting from the first element matching the given value, or false if not found.

#### Scenario: Element found
- **WHEN** evaluating `(member 3 '(1 2 3 4 5))`
- **THEN** the result SHALL be `(3 4 5)`

#### Scenario: Element not found
- **WHEN** evaluating `(member 6 '(1 2 3 4 5))`
- **THEN** the result SHALL be false

#### Scenario: Symbol membership
- **WHEN** evaluating `(member 'c '(a b c d))`
- **THEN** the result SHALL be `(c d)`
