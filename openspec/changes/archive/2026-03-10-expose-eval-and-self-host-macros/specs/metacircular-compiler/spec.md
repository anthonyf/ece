## MODIFIED Requirements

### Requirement: Macro expansion is self-hosted
The ECE compiler (`compiler.scm`) SHALL expand macros using its own `mc-compile-and-go` instead of delegating to the CL `expand-macro` primitive. Macro definitions SHALL continue to be stored as `(params body env)` tuples in the shared `*compile-time-macros*` table.

#### Scenario: Simple macro expansion
- **WHEN** a macro like `(define-macro (my-if c t f) (list 'cond (list c t) (list 'else f)))` is defined and `(my-if #t 1 2)` is compiled
- **THEN** the ECE compiler SHALL expand the macro using `mc-compile-and-go` and compile the expanded form, producing the same result as before

#### Scenario: Macro using existing stdlib macros
- **WHEN** a macro body uses `when`, `let`, or other macros defined in prelude
- **THEN** the expansion SHALL work correctly because `mc-compile-and-go` handles nested macro expansion

#### Scenario: Lexical shadowing prevents macro expansion
- **WHEN** a lambda parameter or `define` shadows a macro name
- **THEN** the compiler SHALL treat it as a variable reference, not a macro call (no change from current behavior)
