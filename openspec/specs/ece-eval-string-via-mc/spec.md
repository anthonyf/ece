## Requirements

### Requirement: ece-eval-string uses the ECE reader via mc-eval
The test helper `ece-eval-string` SHALL parse and evaluate ECE source strings by calling `mc-eval` with an expression that reads via the ECE reader (`open-input-string` + `read` + `eval`). It SHALL NOT depend on `*ece-readtable*` or any CL readtable customization.

#### Scenario: Basic expression evaluation
- **WHEN** `(ece-eval-string "(+ 1 2)")` is called
- **THEN** the result SHALL be `3`

#### Scenario: Scheme boolean literals
- **WHEN** `(ece-eval-string "#f")` is called
- **THEN** the result SHALL be the ECE false value (`*scheme-false*`)

#### Scenario: Hash table literal syntax
- **WHEN** `(ece-eval-string "{a 1 b 2}")` is called
- **THEN** the result SHALL be an ECE hash table with keys `a` and `b`

#### Scenario: String interpolation
- **WHEN** `(ece-eval-string "(let ((x 5)) \"val=$x\")")` is called
- **THEN** the result SHALL be `"val=5"`

#### Scenario: Quasiquote syntax
- **WHEN** `(ece-eval-string "(let ((x 1)) \`(a ,x))")` is called
- **THEN** the result SHALL be `(a 1)`

### Requirement: Tests using #f/#t in quoted s-expressions are converted to ece-eval-string
All tests that embed `#f` or `#t` in CL-read quoted s-expressions SHALL be converted to use `ece-eval-string` with string source. CL's default reader does not support `#f`/`#t` as Scheme booleans.

#### Scenario: Boolean test conversion
- **WHEN** a test previously used `(evaluate '#f)`
- **THEN** it SHALL be rewritten as `(ece-eval-string "#f")`
- **AND** the test behavior SHALL be unchanged
