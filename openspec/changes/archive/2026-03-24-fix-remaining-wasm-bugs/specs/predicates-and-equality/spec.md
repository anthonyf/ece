## MODIFIED Requirements

### Requirement: equal? compares vectors element-wise
`equal?` SHALL recursively compare vector elements when both arguments are vectors.

#### Scenario: Equal vectors
- **WHEN** `(equal? (vector 1 2 3) (vector 1 2 3))` is called
- **THEN** the result SHALL be `#t`

#### Scenario: Unequal vectors (different elements)
- **WHEN** `(equal? (vector 1 2 3) (vector 1 2 4))` is called
- **THEN** the result SHALL be `#f`

#### Scenario: Unequal vectors (different lengths)
- **WHEN** `(equal? (vector 1 2) (vector 1 2 3))` is called
- **THEN** the result SHALL be `#f`

#### Scenario: Nested vectors
- **WHEN** `(equal? (vector (list 1 2) (list 3 4)) (vector (list 1 2) (list 3 4)))` is called
- **THEN** the result SHALL be `#t`
