## ADDED Requirements

### Requirement: If evaluates consequent when predicate is truthy
The evaluator SHALL evaluate the consequent expression when the predicate evaluates to a non-nil value.

#### Scenario: Truthy numeric predicate
- **WHEN** evaluating `(if 1 42 0)`
- **THEN** the result SHALL be `42`

#### Scenario: Truthy comparison predicate
- **WHEN** evaluating `(if (< 1 2) 10 20)`
- **THEN** the result SHALL be `10`

#### Scenario: Truthy symbol predicate
- **WHEN** evaluating `(if (quote t) 1 2)`
- **THEN** the result SHALL be `1`

### Requirement: If evaluates alternative when predicate is nil
The evaluator SHALL evaluate the alternative expression when the predicate evaluates to `nil`.

#### Scenario: Nil predicate takes alternative
- **WHEN** evaluating `(if (quote ()) 10 20)`
- **THEN** the result SHALL be `20`

#### Scenario: False comparison takes alternative
- **WHEN** evaluating `(if (> 1 2) 10 20)`
- **THEN** the result SHALL be `20`

### Requirement: If with omitted alternative returns nil
When the alternative is omitted and the predicate is nil, the evaluator SHALL return `nil`.

#### Scenario: No alternative with false predicate
- **WHEN** evaluating `(if (quote ()) 42)`
- **THEN** the result SHALL be `nil`

#### Scenario: No alternative with true predicate
- **WHEN** evaluating `(if 1 42)`
- **THEN** the result SHALL be `42`

### Requirement: If evaluates subexpressions
The predicate, consequent, and alternative SHALL be fully evaluated expressions, not just literals.

#### Scenario: Computed predicate and branches
- **WHEN** evaluating `(if (= (+ 1 1) 2) (* 3 4) (- 5 1))`
- **THEN** the result SHALL be `12`

#### Scenario: Nested if
- **WHEN** evaluating `(if (< 1 2) (if (< 2 3) 100 200) 300)`
- **THEN** the result SHALL be `100`
