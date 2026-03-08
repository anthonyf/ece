## ADDED Requirements

### Requirement: fold aliases reduce
`fold` SHALL be an alias for `reduce`, accepting `(f init lst)` where `f` takes `(accumulator, element)`.

#### Scenario: Sum with fold
- **WHEN** `(fold + 0 (list 1 2 3 4))` is evaluated
- **THEN** the result SHALL be `10`

### Requirement: fold-left aliases reduce
`fold-left` SHALL be an alias for `reduce`, accepting `(f init lst)` where `f` takes `(accumulator, element)`.

#### Scenario: Sum with fold-left
- **WHEN** `(fold-left + 0 (list 1 2 3))` is evaluated
- **THEN** the result SHALL be `6`

### Requirement: fold-right processes right to left
`fold-right` SHALL accept `(f init lst)` where `f` takes `(element, accumulator)` and processes elements from right to left.

#### Scenario: Cons with fold-right copies list
- **WHEN** `(fold-right cons (list) (list 1 2 3))` is evaluated
- **THEN** the result SHALL be `(1 2 3)`

#### Scenario: Subtraction order matters
- **WHEN** `(fold-right - 0 (list 1 2 3))` is evaluated
- **THEN** the result SHALL be `2` (i.e., `1 - (2 - (3 - 0))`)
