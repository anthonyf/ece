## Requirements

### Requirement: set mutates an existing binding
The evaluator SHALL support `(set <variable> <expression>)` which evaluates `<expression>` and updates the existing binding of `<variable>` in the environment.

#### Scenario: Update a defined variable
- **WHEN** evaluating `(begin (define x 1) (set x 2) x)`
- **THEN** the result SHALL be `2`

#### Scenario: Update with a computed value
- **WHEN** evaluating `(begin (define x 1) (set x (+ x 10)) x)`
- **THEN** the result SHALL be `11`

#### Scenario: set returns the new value
- **WHEN** evaluating `(begin (define x 1) (set x 42))`
- **THEN** the result SHALL be `42`

### Requirement: set signals error for unbound variables
The evaluator SHALL signal an error when `set` is used on a variable that is not bound in any frame.

#### Scenario: Unbound variable error
- **WHEN** evaluating `(set nonexistent 10)`
- **THEN** it SHALL signal an error

### Requirement: set updates the correct frame
The evaluator SHALL find and update the variable in whichever frame it is bound, not just the first frame.

#### Scenario: Update variable in enclosing scope
- **WHEN** a lambda uses `set` on a variable from its enclosing scope
- **THEN** the variable SHALL be updated in the enclosing frame

#### Scenario: Closure mutation via set
- **WHEN** evaluating a counter pattern using `set` inside a closure
- **THEN** successive calls SHALL return incrementing values
