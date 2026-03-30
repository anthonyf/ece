## Requirements

### Requirement: syntax-rules creates a pattern-matching macro transformer
`syntax-rules` SHALL accept a list of literal identifiers and one or more pattern/template clauses. It SHALL return a macro transformer that matches its input against each pattern in order and expands to the corresponding template for the first match.

#### Scenario: Single-clause pattern match
- **WHEN** evaluating `(begin (define-syntax my-const (syntax-rules () ((_ x) (quote x)))) (my-const hello))`
- **THEN** the result SHALL be `hello`

#### Scenario: Multi-clause pattern match selects first matching clause
- **WHEN** evaluating `(begin (define-syntax my-if (syntax-rules () ((_ test then) (cond (test then))) ((_ test then else) (cond (test then) (#t else))))) (my-if #t 42))`
- **THEN** the result SHALL be `42`

#### Scenario: Multi-clause with else branch
- **WHEN** evaluating `(begin (define-syntax my-if (syntax-rules () ((_ test then) (cond (test then))) ((_ test then else) (cond (test then) (#t else))))) (my-if #f 42 99))`
- **THEN** the result SHALL be `99`

### Requirement: syntax-rules supports underscore as wildcard
The `_` pattern element SHALL match any single form without binding it.

#### Scenario: Underscore discards matched form
- **WHEN** evaluating `(begin (define-syntax second (syntax-rules () ((_ _ x) x))) (second 1 2))`
- **THEN** the result SHALL be `2`

### Requirement: syntax-rules supports literal identifier matching
Identifiers listed in the literals list SHALL be matched by identity (not as pattern variables). A pattern containing a literal SHALL only match if the corresponding position in the input contains that exact identifier.

#### Scenario: Literal keyword matching
- **WHEN** evaluating `(begin (define-syntax my-arrow (syntax-rules (=>) ((_ x => y) (list y x)))) (my-arrow 1 => 2))`
- **THEN** the result SHALL be `(2 1)`

#### Scenario: Literal mismatch falls through to next clause
- **WHEN** evaluating `(begin (define-syntax my-arrow (syntax-rules (=>) ((_ x => y) (list y x)) ((_ x y) (list x y)))) (my-arrow 1 2))`
- **THEN** the result SHALL be `(1 2)`

### Requirement: syntax-rules supports ellipsis patterns
The ellipsis token `...` after a pattern variable SHALL match zero or more repetitions of the preceding sub-pattern. In the template, `...` after a template element SHALL replicate that element once for each match.

#### Scenario: Zero-or-more match with no elements
- **WHEN** evaluating `(begin (define-syntax my-list (syntax-rules () ((_ x ...) (list x ...)))) (my-list))`
- **THEN** the result SHALL be `()`

#### Scenario: Ellipsis matches multiple elements
- **WHEN** evaluating `(begin (define-syntax my-list (syntax-rules () ((_ x ...) (list x ...)))) (my-list 1 2 3))`
- **THEN** the result SHALL be `(1 2 3)`

#### Scenario: Ellipsis with fixed prefix
- **WHEN** evaluating `(begin (define-syntax my-cons* (syntax-rules () ((_ first rest ...) (cons first (list rest ...))))) (my-cons* 1 2 3))`
- **THEN** the result SHALL be `(1 2 3)`

### Requirement: syntax-rules provides automatic hygiene for introduced bindings
Identifiers introduced by a template (not present in the pattern) SHALL be renamed via gensym to prevent capture of user-level bindings.

#### Scenario: Introduced temporary does not capture user variable
- **WHEN** evaluating `(begin (define-syntax my-swap! (syntax-rules () ((_ a b) (let ((temp a)) (set! a b) (set! b temp))))) (define temp 10) (define y 20) (my-swap! temp y) (list temp y))`
- **THEN** the result SHALL be `(20 10)`

### Requirement: syntax-rules sub-list patterns
Patterns SHALL support nested list structures. A pattern like `((_ (a b) c))` SHALL match when the corresponding input position is a list of two elements.

#### Scenario: Nested list pattern match
- **WHEN** evaluating `(begin (define-syntax my-let1 (syntax-rules () ((_ (var val) body) ((lambda (var) body) val)))) (my-let1 (x 5) (+ x 1)))`
- **THEN** the result SHALL be `6`

### Requirement: syntax-rules error on no matching clause
If no clause matches the input form, the transformer SHALL signal an error indicating that the syntax is invalid.

#### Scenario: No matching clause raises error
- **WHEN** evaluating `(begin (define-syntax only-two (syntax-rules () ((_ a b) (list a b)))) (only-two 1))`
- **THEN** an error SHALL be signaled

### Requirement: WASM hygiene for free template variables
Free symbols in operator position within syntax-rules templates SHALL be resolved from the global environment on all runtimes, including WASM. The `%global-ref` wrapping SHALL use `lookup-global-variable` to ensure lexical bindings do not shadow template references.

#### Scenario: shadowed + in operator position on WASM
- **WHEN** a syntax-rules macro `add1` with template `(+ e 1)` is used inside `(let ((+ *)) (add1 3))`
- **THEN** the result SHALL be `4` (global `+` used, not local `*`)

#### Scenario: shadowed cons in operator position on WASM
- **WHEN** a syntax-rules macro `my-pair` with template `(cons a b)` is used inside `(let ((cons list)) (my-pair 1 2))`
- **THEN** the result SHALL be `(1 . 2)` (global `cons` used, not local `list`)
