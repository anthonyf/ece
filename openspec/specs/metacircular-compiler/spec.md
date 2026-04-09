## Requirements

### Requirement: Macro expansion is self-hosted
The ECE compiler (`compiler.scm`) SHALL expand macros by calling the compiled macro transformer procedure directly via `execute-compiled-call`. Macro definitions SHALL be compiled into procedures at definition time and stored in the `*compile-time-macros*` table as compiled procedures.

#### Scenario: Simple macro expansion
- **WHEN** a macro like `(define-macro (my-if c t f) (list 'cond (list c t) (list 'else f)))` is defined and `(my-if #t 1 2)` is compiled
- **THEN** the compiler SHALL call the compiled transformer with the unevaluated operands and compile the expanded form, producing the same result as before

#### Scenario: Macro using existing stdlib macros
- **WHEN** a macro body uses `when`, `let`, or other macros defined in prelude
- **THEN** the expansion SHALL work correctly because the transformer was compiled with those macros available

#### Scenario: Lexical shadowing prevents macro expansion
- **WHEN** a lambda parameter, `define`, `let` binding, or `let*` binding shadows a macro name
- **THEN** the compiler SHALL treat it as a variable reference, not a macro call

### Requirement: Compiler recognizes let as a special form
The compiler SHALL recognize `(let ((var init) ...) body)` in its dispatch and compile it directly, bypassing macro expansion. Named `let` (`(let name ((var init) ...) body)`) SHALL NOT be intercepted and SHALL fall through to macro expansion.

#### Scenario: let dispatched before macro expansion
- **WHEN** compiling `(let ((x 1)) x)`
- **THEN** the compiler SHALL handle it via `mc-compile-let`, not via macro expansion to `((lambda (x) x) 1)`

#### Scenario: Named let falls through
- **WHEN** compiling `(let loop ((n 10)) (if (= n 0) n (loop (- n 1))))`
- **THEN** the compiler SHALL NOT intercept this as a direct let; it SHALL fall through to macro expansion

### Requirement: Compiler recognizes let* as a special form
The compiler SHALL recognize `(let* ((var init) ...) body)` in its dispatch and compile it directly, bypassing macro expansion.

#### Scenario: let* dispatched before macro expansion
- **WHEN** compiling `(let* ((x 1) (y x)) y)`
- **THEN** the compiler SHALL handle it via `mc-compile-let*`, not via macro expansion to nested lambda applications

### Requirement: let/let* bindings shadow macros
Bindings introduced by `let` and `let*` SHALL shadow macros with the same name, just as lambda parameters and internal `define` do.

#### Scenario: let binding shadows macro
- **WHEN** compiling `(let ((when 42)) when)` where `when` is a macro
- **THEN** the result SHALL be `42`, not a macro expansion error

#### Scenario: let* binding shadows macro for subsequent bindings
- **WHEN** compiling `(let* ((when 42) (x when)) x)` where `when` is a macro
- **THEN** the result SHALL be `42`
