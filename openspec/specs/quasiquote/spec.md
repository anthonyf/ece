## Requirements

### Requirement: quasiquote returns a template with literal parts preserved
The evaluator SHALL support `quasiquote` as a special form. When a `quasiquote` template contains no `unquote` or `unquote-splicing` forms, it SHALL behave like `quote`.

#### Scenario: All-literal template
- **WHEN** evaluating `(quasiquote (a b c))`
- **THEN** the result SHALL be `(a b c)`

#### Scenario: Atomic template
- **WHEN** evaluating `(quasiquote hello)`
- **THEN** the result SHALL be `hello`

### Requirement: unquote evaluates and inserts a value into a quasiquote template
The evaluator SHALL support `(unquote expr)` within a `quasiquote` template. The `expr` SHALL be evaluated and its value inserted at that position.

#### Scenario: Unquote a variable
- **WHEN** evaluating `(begin (define x 42) (quasiquote (a (unquote x) c)))`
- **THEN** the result SHALL be `(a 42 c)`

#### Scenario: Unquote an expression
- **WHEN** evaluating `(quasiquote (result (unquote (+ 1 2))))`
- **THEN** the result SHALL be `(result 3)`

#### Scenario: Unquote in tail position
- **WHEN** evaluating `(begin (define xs (quote (1 2 3))) (quasiquote (prefix (unquote xs))))`
- **THEN** the result SHALL be `(prefix (1 2 3))`

### Requirement: unquote-splicing splices a list into a quasiquote template
The evaluator SHALL support `(unquote-splicing expr)` within a `quasiquote` template. The `expr` SHALL be evaluated and the resulting list spliced into the surrounding list.

#### Scenario: Splice a list
- **WHEN** evaluating `(begin (define xs (quote (1 2 3))) (quasiquote (a (unquote-splicing xs) d)))`
- **THEN** the result SHALL be `(a 1 2 3 d)`

#### Scenario: Splice an empty list
- **WHEN** evaluating `(begin (define xs (quote ())) (quasiquote (a (unquote-splicing xs) b)))`
- **THEN** the result SHALL be `(a b)`

### Requirement: quasiquote works in macro definitions
The evaluator SHALL allow `quasiquote` to be used within macro bodies to construct output forms.

#### Scenario: Macro using quasiquote
- **WHEN** evaluating `(begin (define-macro (my-if test then) (quasiquote (if (unquote test) (unquote then)))) (my-if (= 1 1) 42))`
- **THEN** the result SHALL be `42`

### Requirement: REPL reader supports backtick syntax
The ECE reader SHALL transform `` ` `` into `quasiquote`, `,` into `unquote`, and `,@` into `unquote-splicing` so that backtick syntax works in the REPL.

#### Scenario: Backtick syntax in reader
- **WHEN** reading `` `(a ,b) `` via the ECE reader
- **THEN** the result SHALL be `(quasiquote (a (unquote b)))`

#### Scenario: Splicing syntax in reader
- **WHEN** reading `` `(a ,@b) `` via the ECE reader
- **THEN** the result SHALL be `(quasiquote (a (unquote-splicing b)))`
