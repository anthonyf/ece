## ADDED Requirements

### Requirement: metacircular compiler computes lexical addresses for bound variables
The metacircular compiler SHALL maintain `*mc-compile-lexical-env*` as a list of frames (each frame a list of variable names). When compiling a variable reference, assignment, or define, the compiler SHALL search this environment via `mc-find-variable` and, if found, return a lexical address `(depth . offset)`.

#### Scenario: Variable in innermost frame
- **WHEN** compiling variable `x` with compile-time env `((x y z))`
- **THEN** `mc-find-variable` SHALL return `(0 . 0)`

#### Scenario: Variable in outer frame
- **WHEN** compiling variable `a` with compile-time env `((x y) (a b c))`
- **THEN** `mc-find-variable` SHALL return `(1 . 0)`

#### Scenario: Variable at non-zero offset
- **WHEN** compiling variable `c` with compile-time env `((x y) (a b c))`
- **THEN** `mc-find-variable` SHALL return `(1 . 2)`

#### Scenario: Global variable has no lexical address
- **WHEN** compiling variable `display` with compile-time env `((x y))`
- **THEN** `mc-find-variable` SHALL return `#f`

### Requirement: metacircular compiler emits lexical-ref for bound variable references
When a variable has a lexical address, `mc-compile-variable` SHALL emit `(assign target (op lexical-ref) (const depth) (const offset) (reg env))` instead of `(assign target (op lookup-variable-value) (const name) (reg env))`.

#### Scenario: Lexical variable reference
- **WHEN** `(lambda (x y) x)` is compiled by the metacircular compiler
- **THEN** the reference to `x` SHALL emit `(assign val (op lexical-ref) (const 0) (const 0) (reg env))`

#### Scenario: Nested lambda variable reference
- **WHEN** `(lambda (x) (lambda (y) x))` is compiled by the metacircular compiler
- **THEN** the reference to `x` in the inner lambda SHALL emit `(assign val (op lexical-ref) (const 1) (const 0) (reg env))`

#### Scenario: Global variable falls back to name-based lookup
- **WHEN** `(lambda (x) (display x))` is compiled by the metacircular compiler
- **THEN** the reference to `display` SHALL emit `(assign proc (op lookup-variable-value) (const display) (reg env))`

### Requirement: metacircular compiler emits lexical-set! for bound variable assignments
When a variable has a lexical address, `mc-compile-assignment` SHALL emit `(perform (op lexical-set!) (const depth) (const offset) (reg val) (reg env))` instead of `(perform (op set-variable-value!) (const name) (reg val) (reg env))`.

#### Scenario: Lexical variable assignment
- **WHEN** `(lambda (x) (set x 10))` is compiled by the metacircular compiler
- **THEN** the set form SHALL emit `(perform (op lexical-set!) (const 0) (const 0) (reg val) (reg env))`

#### Scenario: Global variable assignment falls back to name-based set
- **WHEN** `(set some-global 42)` is compiled at top level by the metacircular compiler
- **THEN** the set form SHALL emit `(perform (op set-variable-value!) (const some-global) (reg val) (reg env))`

### Requirement: metacircular compiler emits lexical-set! for internal defines
When a `define` form appears inside a lambda body and has a lexical address (pre-allocated slot), `mc-compile-define` SHALL emit `(perform (op lexical-set!) ...)` instead of `(perform (op define-variable!) ...)`.

#### Scenario: Internal define uses lexical-set!
- **WHEN** `(lambda () (define x 10) x)` is compiled by the metacircular compiler
- **THEN** `(define x 10)` SHALL compile as `(perform (op lexical-set!) (const 0) (const 0) (reg val) (reg env))`
- **AND** the reference to `x` SHALL compile as `(assign val (op lexical-ref) (const 0) (const 0) (reg env))`

#### Scenario: Top-level define still uses define-variable!
- **WHEN** `(define x 42)` is compiled at top level by the metacircular compiler
- **THEN** it SHALL emit `(perform (op define-variable!) (const x) (reg val) (reg env))`

### Requirement: metacircular compiler emits 4-arg extend-environment with extra-slots
`mc-compile-lambda-body` SHALL compute the count of internal defines and emit `extend-environment` with four arguments: params, argl, env, and extra-slots.

#### Scenario: Lambda with no internal defines
- **WHEN** `(lambda (x y) (+ x y))` is compiled
- **THEN** the extend-environment call SHALL include `(const 0)` as the extra-slots argument

#### Scenario: Lambda with internal defines
- **WHEN** `(lambda (x) (define y 10) (+ x y))` is compiled
- **THEN** the extend-environment call SHALL include `(const 1)` as the extra-slots argument
- **AND** the compile-time frame SHALL be `(x y)` — params followed by define names

#### Scenario: Lambda with multiple internal defines
- **WHEN** `(lambda () (define a 1) (define b 2) (define c 3) a)` is compiled
- **THEN** the extend-environment call SHALL include `(const 3)` as the extra-slots argument

### Requirement: mc-extract-define-names recurses into begin and expands macros
`mc-extract-define-names` SHALL find define forms nested inside `begin` blocks and inside macro expansions, matching the CL compiler's `extract-define-names` behavior.

#### Scenario: Define inside begin block
- **WHEN** extracting define names from body `((begin (define x 1) (define y 2)) (+ x y))`
- **THEN** the result SHALL include both `x` and `y`

#### Scenario: Define hidden inside macro expansion
- **WHEN** a macro `my-macro` expands to `(begin (define helper 1) helper)`
- **AND** extracting define names from body `((my-macro) (+ helper 1))`
- **THEN** the result SHALL include `helper`

#### Scenario: Define inside if branches
- **WHEN** extracting define names from body `((if test (define a 1) (define b 2)))`
- **THEN** the result SHALL include both `a` and `b`

### Requirement: metacircular compiler tracks macro shadows separately from lexical env
The compiler SHALL maintain `*mc-compile-macro-shadows*` as a separate flat list for names that shadow macros at begin-block level (without creating lexical frames). The macro shadow check SHALL consult both `mc-find-variable` and `*mc-compile-macro-shadows*`.

#### Scenario: Begin-level define shadows macro
- **WHEN** a macro `foo` is defined
- **AND** `(begin (define foo 42) (foo))` is compiled
- **THEN** `(foo)` SHALL be compiled as a variable reference, not a macro call

#### Scenario: Lambda parameter shadows macro
- **WHEN** a macro `bar` is defined
- **AND** `(lambda (bar) (bar 1 2))` is compiled
- **THEN** `(bar 1 2)` in the body SHALL be compiled as a procedure call, not a macro expansion
