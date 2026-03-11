## MODIFIED Requirements

### Requirement: define-macro creates macro transformers
The evaluator SHALL support `define-macro` as a special form that binds a name to a macro transformer. The transformer SHALL be compiled into a procedure at definition time and stored in the macro table as a compiled procedure. At expansion time, the compiled transformer SHALL be called with the unevaluated operands and its return value SHALL be the expanded form.

#### Scenario: Simple macro definition and expansion
- **WHEN** evaluating `(begin (define-macro (my-const name) (list (quote quote) name)) (my-const hello))`
- **THEN** the result SHALL be `hello`

#### Scenario: Macro receives unevaluated operands
- **WHEN** evaluating `(begin (define-macro (identity-macro expr) expr) (identity-macro (+ 1 2)))`
- **THEN** the result SHALL be `3`

#### Scenario: Macro with multiple body expressions
- **WHEN** evaluating `(begin (define-macro (last-of a b) b) (last-of (error "never") (+ 10 20)))`
- **THEN** the result SHALL be `30`
