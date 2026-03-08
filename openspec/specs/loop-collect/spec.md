## ADDED Requirements

### Requirement: loop runs body indefinitely until break
`loop` SHALL execute its body repeatedly until `(break value)` is called, returning the value passed to `break`.

#### Scenario: Simple countdown
- **WHEN** a loop decrements a counter and breaks at zero
- **THEN** the loop SHALL return the break value

#### Scenario: Break with value
- **WHEN** `(let ((x 5)) (loop (if (= x 0) (break "done")) (set x (- x 1))))` is evaluated
- **THEN** the result SHALL be `"done"`

### Requirement: collect maps over a list concisely
`collect` SHALL accept a binding `(var list-expr)` and a body, and return a list of body results for each element.

#### Scenario: Square numbers
- **WHEN** `(collect (x (range 5)) (* x x))` is evaluated
- **THEN** the result SHALL be `(0 1 4 9 16)`

#### Scenario: Transform strings
- **WHEN** `(collect (s (list "a" "b" "c")) (string-append s "!"))` is evaluated
- **THEN** the result SHALL be `("a!" "b!" "c!")`
