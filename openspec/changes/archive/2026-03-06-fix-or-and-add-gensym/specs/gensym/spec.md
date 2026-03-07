## ADDED Requirements

### Requirement: gensym generates unique symbols
The evaluator SHALL provide `gensym` as a primitive procedure that returns a unique, uninterned symbol each time it is called. Each call SHALL return a distinct symbol.

#### Scenario: gensym returns a symbol
- **WHEN** evaluating `(symbol? (gensym))`
- **THEN** the result SHALL be true

#### Scenario: gensym returns unique symbols
- **WHEN** evaluating `(eq? (gensym) (gensym))`
- **THEN** the result SHALL be false
