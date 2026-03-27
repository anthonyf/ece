## Requirements

### Requirement: define-syntax registers a syntax-rules transformer as a macro
`define-syntax` SHALL bind a name to a `syntax-rules` transformer. The transformer SHALL be stored in the same macro table used by `define-macro`, so the compiler's existing macro expansion dispatch handles it transparently.

#### Scenario: define-syntax with syntax-rules creates a usable macro
- **WHEN** evaluating `(begin (define-syntax my-when (syntax-rules () ((_ test body ...) (if test (begin body ...))))) (my-when #t 42))`
- **THEN** the result SHALL be `42`

#### Scenario: define-syntax macros coexist with define-macro macros
- **WHEN** evaluating `(begin (define-macro (dm-add a b) (list (quote +) a b)) (define-syntax sr-add (syntax-rules () ((_ a b) (+ a b)))) (+ (dm-add 1 2) (sr-add 3 4)))`
- **THEN** the result SHALL be `10`

### Requirement: define-syntax macros are shadowed by lexical bindings
When a lexical binding (lambda parameter or local define) uses the same name as a `define-syntax` macro, the lexical binding SHALL take precedence, consistent with existing `define-macro` shadowing behavior.

#### Scenario: Lambda parameter shadows define-syntax macro
- **WHEN** evaluating `(begin (define-syntax foo (syntax-rules () ((_ x) (+ x 1)))) ((lambda (foo) foo) 42))`
- **THEN** the result SHALL be `42`

### Requirement: define-syntax macros are available at compile time
A `define-syntax` form SHALL register the transformer immediately at compile time (not at runtime), so subsequent expressions in the same compilation unit can use the macro.

#### Scenario: Macro usable in same compilation unit
- **WHEN** evaluating `(begin (define-syntax double (syntax-rules () ((_ x) (+ x x)))) (double 21))`
- **THEN** the result SHALL be `42`
