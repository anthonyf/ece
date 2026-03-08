## ADDED Requirements

### Requirement: any returns true if any element satisfies predicate
`any` SHALL accept a predicate and a list and return `#t` if the predicate returns truthy for any element, `#f` otherwise. It SHALL short-circuit on the first truthy result.

#### Scenario: Element found
- **WHEN** `(any odd? (list 2 3 4))` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: No element found
- **WHEN** `(any odd? (list 2 4 6))` is evaluated
- **THEN** the result SHALL be `#f`

#### Scenario: Empty list
- **WHEN** `(any odd? (list))` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: every returns true if all elements satisfy predicate
`every` SHALL accept a predicate and a list and return `#t` if the predicate returns truthy for all elements, `#f` otherwise. It SHALL short-circuit on the first falsy result.

#### Scenario: All elements match
- **WHEN** `(every even? (list 2 4 6))` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: Some element fails
- **WHEN** `(every even? (list 2 3 6))` is evaluated
- **THEN** the result SHALL be `#f`

#### Scenario: Empty list
- **WHEN** `(every even? (list))` is evaluated
- **THEN** the result SHALL be `#t`

### Requirement: compose returns a function applying f after g
`compose` SHALL accept two functions and return a new function that applies `g` to its argument, then applies `f` to the result.

#### Scenario: Compose two functions
- **WHEN** `((compose car cdr) (list 1 2 3))` is evaluated
- **THEN** the result SHALL be `2`

### Requirement: identity returns its argument unchanged
`identity` SHALL accept one argument and return it.

#### Scenario: Identity on a value
- **WHEN** `(identity 42)` is evaluated
- **THEN** the result SHALL be `42`

#### Scenario: Identity as a function argument
- **WHEN** `(map identity (list 1 2 3))` is evaluated
- **THEN** the result SHALL be `(1 2 3)`

### Requirement: range generates a list of integers
`range` SHALL accept a non-negative integer `n` and return a list `(0 1 2 ... n-1)`.

#### Scenario: Range of 5
- **WHEN** `(range 5)` is evaluated
- **THEN** the result SHALL be `(0 1 2 3 4)`

#### Scenario: Range of 0
- **WHEN** `(range 0)` is evaluated
- **THEN** the result SHALL be `()`

#### Scenario: Range of 1
- **WHEN** `(range 1)` is evaluated
- **THEN** the result SHALL be `(0)`
