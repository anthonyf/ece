## MODIFIED Requirements

### Requirement: Lexical shadowing prevents macro expansion
- **WHEN** a lambda parameter, `define`, `let` binding, or `let*` binding shadows a macro name
- **THEN** the compiler SHALL treat it as a variable reference, not a macro call

## ADDED Requirements

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
