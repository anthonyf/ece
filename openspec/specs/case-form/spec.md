## Requirements

### Requirement: case matches a key against constant datums
The evaluator SHALL provide `case` as a macro that evaluates a key expression once, then tests it against datum lists in each clause using `equal?`. The first matching clause's body SHALL be evaluated. An `else` clause SHALL match if no other clause matches. If no clause matches and no `else` is present, the result SHALL be `nil`.

#### Scenario: Match single datum
- **WHEN** evaluating `(case (+ 1 1) ((1) 10) ((2) 20) ((3) 30))`
- **THEN** the result SHALL be `20`

#### Scenario: Match in datum list
- **WHEN** evaluating `(case 3 ((1 2) 'low) ((3 4) 'high))`
- **THEN** the result SHALL be `high`

#### Scenario: else clause
- **WHEN** evaluating `(case 99 ((1) 'one) (else 'other))`
- **THEN** the result SHALL be `other`

#### Scenario: No match returns nil
- **WHEN** evaluating `(case 5 ((1) 'one) ((2) 'two))`
- **THEN** the result SHALL be `nil`

#### Scenario: Key expression evaluated once
- **WHEN** evaluating `(begin (define counter 0) (case (begin (set counter (+ counter 1)) counter) ((1) 'one) ((2) 'two)) counter)`
- **THEN** the result SHALL be `1`

#### Scenario: Match symbol datums
- **WHEN** evaluating `(case (quote b) ((a) 1) ((b) 2) ((c) 3))`
- **THEN** the result SHALL be `2`
