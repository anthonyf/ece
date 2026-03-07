## ADDED Requirements

### Requirement: Generated special form predicates
The special form predicate functions SHALL be generated from their symbol/name pairs rather than written as individual function definitions. Each generated predicate SHALL produce the same result as the hand-written version: `(and (listp expr) (eq (car expr) 'SYMBOL))`.

#### Scenario: All predicates still exist as named functions
- **WHEN** the generated predicates are loaded
- **THEN** the functions `assignment-p`, `quoted-p`, `lambda-p`, `begin-p`, `if-p`, `callcc-p`, `define-p`, `apply-form-p`, `define-macro-p`, and `quasiquote-p` SHALL all exist and be callable

#### Scenario: Predicates produce identical results
- **WHEN** any generated predicate is called with an expression
- **THEN** it SHALL return the same result as the original hand-written predicate for all inputs (lists starting with the correct symbol return truthy, all other inputs return nil)

#### Scenario: Evaluator dispatch unchanged
- **WHEN** the evaluator's `:ev-dispatch` block runs
- **THEN** it SHALL use the same predicate functions and produce the same dispatch behavior as before
