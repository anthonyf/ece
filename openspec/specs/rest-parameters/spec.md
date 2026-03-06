## Requirements

### Requirement: Lambda supports rest parameters via dotted pair syntax
The evaluator SHALL support `(lambda (x y . rest) body)` where `rest` captures any remaining arguments as a list.

#### Scenario: Rest parameter captures extra arguments
- **WHEN** evaluating `((lambda (x . rest) rest) 1 2 3)`
- **THEN** the result SHALL be `(2 3)`

#### Scenario: Rest parameter with no extra arguments
- **WHEN** evaluating `((lambda (x . rest) rest) 1)`
- **THEN** the result SHALL be `nil`

#### Scenario: Rest parameter with fixed and rest args
- **WHEN** evaluating `((lambda (x y . rest) (list x y rest)) 1 2 3 4)`
- **THEN** the result SHALL be `(1 2 (3 4))`

#### Scenario: Rest-only parameter (symbol instead of list)
- **WHEN** evaluating `((lambda args args) 1 2 3)`
- **THEN** the result SHALL be `(1 2 3)`

### Requirement: Define shorthand supports rest parameters
The evaluator SHALL support `(define (f x . rest) body)` for defining variadic functions.

#### Scenario: Define with rest parameter
- **WHEN** evaluating `(begin (define (f x . rest) rest) (f 1 2 3))`
- **THEN** the result SHALL be `(2 3)`

#### Scenario: Define rest-only
- **WHEN** evaluating `(begin (define (f . args) args) (f 1 2 3))`
- **THEN** the result SHALL be `(1 2 3)`
