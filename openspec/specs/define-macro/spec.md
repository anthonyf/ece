## Requirements

### Requirement: define-macro creates macro transformers
The evaluator SHALL support `define-macro` as a special form that binds a name to a macro transformer. The transformer SHALL be stored in the environment as `(macro params body env)`.

#### Scenario: Simple macro definition and expansion
- **WHEN** evaluating `(begin (define-macro (my-const name) (list (quote quote) name)) (my-const hello))`
- **THEN** the result SHALL be `hello`

#### Scenario: Macro receives unevaluated operands
- **WHEN** evaluating `(begin (define-macro (identity-macro expr) expr) (identity-macro (+ 1 2)))`
- **THEN** the result SHALL be `3`

#### Scenario: Macro with multiple body expressions
- **WHEN** evaluating `(begin (define-macro (last-of a b) b) (last-of (error "never") (+ 10 20)))`
- **THEN** the result SHALL be `30`

### Requirement: cond derived form is available
The evaluator SHALL provide `cond` as a macro that expands to nested `if` expressions. Each clause SHALL support multiple body expressions, which are wrapped in `begin`. A clause with the test `else` SHALL be treated as always-true. A clause with the test `t` SHALL also work as a catch-all since `t` is self-evaluating and truthy.

#### Scenario: First true clause
- **WHEN** evaluating `(cond ((= 1 1) 10) ((= 2 3) 20))`
- **THEN** the result SHALL be `10`

#### Scenario: Second clause matches
- **WHEN** evaluating `(cond ((= 1 2) 10) ((= 2 2) 20))`
- **THEN** the result SHALL be `20`

#### Scenario: No clause matches returns nil
- **WHEN** evaluating `(cond ((= 1 2) 10) ((= 3 4) 20))`
- **THEN** the result SHALL be `nil`

#### Scenario: Multi-expression clause body
- **WHEN** evaluating `(begin (define x 0) (cond ((= 1 1) (set x 10) (+ x 5))) x)`
- **THEN** the result SHALL be `10`

#### Scenario: else clause as catch-all
- **WHEN** evaluating `(cond ((= 1 2) 10) (else 99))`
- **THEN** the result SHALL be `99`

#### Scenario: t clause as catch-all
- **WHEN** evaluating `(cond ((= 1 2) 10) (t 99))`
- **THEN** the result SHALL be `99`

### Requirement: let derived form is available
The evaluator SHALL provide `let` as a macro that expands to a lambda application.

#### Scenario: Simple let binding
- **WHEN** evaluating `(let ((x 10) (y 20)) (+ x y))`
- **THEN** the result SHALL be `30`

#### Scenario: Let bindings do not see each other
- **WHEN** evaluating `(begin (define x 1) (let ((x 10) (y x)) y))`
- **THEN** the result SHALL be `1`

### Requirement: let* derived form is available
The evaluator SHALL provide `let*` as a macro that expands to nested `let` expressions. Each binding SHALL be visible to subsequent bindings.

#### Scenario: Sequential bindings
- **WHEN** evaluating `(let* ((x 10) (y (+ x 5))) y)`
- **THEN** the result SHALL be `15`

#### Scenario: Single binding
- **WHEN** evaluating `(let* ((x 42)) x)`
- **THEN** the result SHALL be `42`

### Requirement: and derived form is available
The evaluator SHALL provide `and` as a macro. `and` SHALL return the last truthy value if all values are truthy, or the first falsy value.

#### Scenario: All truthy
- **WHEN** evaluating `(and 1 2 3)`
- **THEN** the result SHALL be `3`

#### Scenario: Short-circuit on false
- **WHEN** evaluating `(and 1 (quote ()) 3)`
- **THEN** the result SHALL be `nil`

#### Scenario: Empty and
- **WHEN** evaluating `(and)`
- **THEN** the result SHALL be truthy

### Requirement: or derived form is available
The evaluator SHALL provide `or` as a macro. `or` SHALL return the first truthy value, or the last value if none are truthy. Each argument SHALL be evaluated at most once.

#### Scenario: First truthy
- **WHEN** evaluating `(or (quote ()) 2 3)`
- **THEN** the result SHALL be `2`

#### Scenario: All falsy
- **WHEN** evaluating `(or (quote ()) (quote ()))`
- **THEN** the result SHALL be `nil`

#### Scenario: Empty or
- **WHEN** evaluating `(or)`
- **THEN** the result SHALL be `nil`

#### Scenario: No double evaluation of truthy argument
- **WHEN** evaluating `(begin (define counter 0) (or (begin (set counter (+ counter 1)) counter) 99) counter)`
- **THEN** the result SHALL be `1`

### Requirement: when derived form is available
The evaluator SHALL provide `when` as a macro. `when` SHALL evaluate the body only if the test is truthy.

#### Scenario: Truthy test evaluates body
- **WHEN** evaluating `(when (= 1 1) 42)`
- **THEN** the result SHALL be `42`

#### Scenario: Falsy test returns nil
- **WHEN** evaluating `(when (= 1 2) 42)`
- **THEN** the result SHALL be `nil`

### Requirement: unless derived form is available
The evaluator SHALL provide `unless` as a macro. `unless` SHALL evaluate the body only if the test is falsy.

#### Scenario: Falsy test evaluates body
- **WHEN** evaluating `(unless (= 1 2) 42)`
- **THEN** the result SHALL be `42`

#### Scenario: Truthy test returns nil
- **WHEN** evaluating `(unless (= 1 1) 42)`
- **THEN** the result SHALL be `nil`
