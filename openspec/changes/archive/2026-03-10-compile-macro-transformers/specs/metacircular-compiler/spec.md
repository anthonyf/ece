## MODIFIED Requirements

### Requirement: Macro expansion is self-hosted
The ECE compiler (`compiler.scm`) SHALL expand macros by calling the compiled macro transformer procedure directly via `execute-compiled-call`. Macro definitions SHALL be compiled into procedures at definition time and stored in the `*compile-time-macros*` table as compiled procedures.

#### Scenario: Simple macro expansion
- **WHEN** a macro like `(define-macro (my-if c t f) (list 'cond (list c t) (list 'else f)))` is defined and `(my-if #t 1 2)` is compiled
- **THEN** the compiler SHALL call the compiled transformer with the unevaluated operands and compile the expanded form, producing the same result as before

#### Scenario: Macro using existing stdlib macros
- **WHEN** a macro body uses `when`, `let`, or other macros defined in prelude
- **THEN** the expansion SHALL work correctly because the transformer was compiled with those macros available

#### Scenario: Lexical shadowing prevents macro expansion
- **WHEN** a lambda parameter or `define` shadows a macro name
- **THEN** the compiler SHALL treat it as a variable reference, not a macro call (no change from current behavior)
