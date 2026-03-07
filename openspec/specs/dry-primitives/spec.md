## ADDED Requirements

### Requirement: Single source of truth for primitive alist
The primitive procedure alist SHALL be defined exactly once as `*primitive-procedures*`. The variables `*primitive-procedure-names*` and `*primitive-procedure-objects*` SHALL be derived from `*primitive-procedures*` using `mapcar`.

#### Scenario: Alist defined once
- **WHEN** `src/main.lisp` is inspected
- **THEN** there SHALL be exactly one copy of the primitive alist, stored in `*primitive-procedures*`

#### Scenario: Names derived correctly
- **WHEN** `*primitive-procedure-names*` is evaluated
- **THEN** it SHALL contain the same list of names as the current implementation (bare symbols for same-name primitives, car of dotted pairs for renamed primitives)

#### Scenario: Objects derived correctly
- **WHEN** `*primitive-procedure-objects*` is evaluated
- **THEN** it SHALL contain the same list of `(primitive SYMBOL)` entries as the current implementation

### Requirement: Wrapper primitives use alist format
The dolist block that registers wrapper-based primitives SHALL use a declarative alist (`*wrapper-primitives*`) instead of verbose inline `(cons ... (list ...))` expressions.

#### Scenario: Wrapper alist registration
- **WHEN** `*wrapper-primitives*` is processed
- **THEN** each entry SHALL be registered in `*global-env*` as `(name . (primitive sym))`, matching current behavior

#### Scenario: All existing wrapper primitives preserved
- **WHEN** the wrapper registration runs
- **THEN** all 25 current wrapper primitives (read, display, newline, etc.) SHALL be registered with the same names and CL function bindings as before
