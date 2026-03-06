## Requirements

### Requirement: Type predicates are available
The evaluator SHALL provide `number?`, `string?`, `symbol?`, `boolean?`, and `zero?` as primitive procedures.

#### Scenario: number? on integer
- **WHEN** evaluating `(number? 42)`
- **THEN** the result SHALL be true

#### Scenario: number? on string
- **WHEN** evaluating `(number? "hello")`
- **THEN** the result SHALL be false

#### Scenario: string? on string
- **WHEN** evaluating `(string? "hello")`
- **THEN** the result SHALL be true

#### Scenario: string? on number
- **WHEN** evaluating `(string? 42)`
- **THEN** the result SHALL be false

#### Scenario: symbol? on symbol
- **WHEN** evaluating `(symbol? (quote foo))`
- **THEN** the result SHALL be true

#### Scenario: symbol? on number
- **WHEN** evaluating `(symbol? 42)`
- **THEN** the result SHALL be false

#### Scenario: boolean? on true
- **WHEN** evaluating `(boolean? t)`
- **THEN** the result SHALL be true

#### Scenario: boolean? on nil
- **WHEN** evaluating `(boolean? (quote ()))`
- **THEN** the result SHALL be true

#### Scenario: boolean? on number
- **WHEN** evaluating `(boolean? 42)`
- **THEN** the result SHALL be false

#### Scenario: zero? on zero
- **WHEN** evaluating `(zero? 0)`
- **THEN** the result SHALL be true

#### Scenario: zero? on non-zero
- **WHEN** evaluating `(zero? 5)`
- **THEN** the result SHALL be false

### Requirement: Equality primitives are available
The evaluator SHALL provide `eq?` (identity comparison) and `equal?` (structural comparison) as primitive procedures.

#### Scenario: eq? on same symbol
- **WHEN** evaluating `(eq? (quote a) (quote a))`
- **THEN** the result SHALL be true

#### Scenario: eq? on different symbols
- **WHEN** evaluating `(eq? (quote a) (quote b))`
- **THEN** the result SHALL be false

#### Scenario: equal? on identical lists
- **WHEN** evaluating `(equal? (quote (1 2 3)) (quote (1 2 3)))`
- **THEN** the result SHALL be true

#### Scenario: equal? on different lists
- **WHEN** evaluating `(equal? (quote (1 2)) (quote (1 3)))`
- **THEN** the result SHALL be false

#### Scenario: equal? on strings
- **WHEN** evaluating `(equal? "hello" "hello")`
- **THEN** the result SHALL be true

### Requirement: Numeric utility primitives are available
The evaluator SHALL provide `modulo`, `abs`, `min`, `max`, `even?`, `odd?`, `positive?`, and `negative?` as primitive procedures.

#### Scenario: modulo
- **WHEN** evaluating `(modulo 10 3)`
- **THEN** the result SHALL be `1`

#### Scenario: abs on negative
- **WHEN** evaluating `(abs -5)`
- **THEN** the result SHALL be `5`

#### Scenario: min
- **WHEN** evaluating `(min 3 1 4 1 5)`
- **THEN** the result SHALL be `1`

#### Scenario: max
- **WHEN** evaluating `(max 3 1 4 1 5)`
- **THEN** the result SHALL be `5`

#### Scenario: even? on even
- **WHEN** evaluating `(even? 4)`
- **THEN** the result SHALL be true

#### Scenario: even? on odd
- **WHEN** evaluating `(even? 3)`
- **THEN** the result SHALL be false

#### Scenario: odd? on odd
- **WHEN** evaluating `(odd? 3)`
- **THEN** the result SHALL be true

#### Scenario: positive? on positive
- **WHEN** evaluating `(positive? 5)`
- **THEN** the result SHALL be true

#### Scenario: positive? on negative
- **WHEN** evaluating `(positive? -1)`
- **THEN** the result SHALL be false

#### Scenario: negative? on negative
- **WHEN** evaluating `(negative? -1)`
- **THEN** the result SHALL be true
