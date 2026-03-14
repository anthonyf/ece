## Requirements

### Requirement: compiler computes lexical addresses for bound variables
The compiler SHALL maintain a compile-time lexical environment as a list of frames (each frame a list of variable names). When compiling a variable reference or assignment, the compiler SHALL search this environment for the variable and, if found, return a lexical address `(depth . offset)`.

#### Scenario: Variable in innermost frame
- **WHEN** compiling variable `x` with compile-time env `((x y z))`
- **THEN** the compiler SHALL compute lexical address `(0 . 0)`

#### Scenario: Variable in outer frame
- **WHEN** compiling variable `a` with compile-time env `((x y) (a b c))`
- **THEN** the compiler SHALL compute lexical address `(1 . 0)`

#### Scenario: Variable at non-zero offset
- **WHEN** compiling variable `c` with compile-time env `((x y) (a b c))`
- **THEN** the compiler SHALL compute lexical address `(1 . 2)`

#### Scenario: Global variable has no lexical address
- **WHEN** compiling variable `display` with compile-time env `((x y))`
- **THEN** `find-variable` SHALL return nil
- **AND** the compiler SHALL emit a name-based `lookup-variable-value` instruction

### Requirement: compiler emits lexical-ref for bound variable references
When a variable has a lexical address, the compiler SHALL emit `(assign target (op lexical-ref) (const depth) (const offset) (reg env))` instead of `(assign target (op lookup-variable-value) (const name) (reg env))`.

#### Scenario: Lexical variable reference
- **WHEN** `(lambda (x y) x)` is compiled
- **THEN** the reference to `x` in the body SHALL emit `(assign val (op lexical-ref) (const 0) (const 0) (reg env))`

#### Scenario: Nested lambda variable reference
- **WHEN** `(lambda (x) (lambda (y) x))` is compiled
- **THEN** the reference to `x` in the inner lambda SHALL emit `(assign val (op lexical-ref) (const 1) (const 0) (reg env))`

### Requirement: compiler emits lexical-set! for bound variable assignments
When a variable has a lexical address, the compiler SHALL emit `(perform (op lexical-set!) (const depth) (const offset) (reg val) (reg env))` instead of `(perform (op set-variable-value!) (const name) (reg val) (reg env))`.

#### Scenario: Lexical variable assignment
- **WHEN** `(lambda (x) (set x 10))` is compiled
- **THEN** the set form SHALL emit `(perform (op lexical-set!) (const 0) (const 0) (reg val) (reg env))`

### Requirement: runtime provides lexical-ref operation
The runtime SHALL provide a `lexical-ref` function that traverses `depth` frames in the environment and returns the value at `offset` in that frame's vector.

#### Scenario: Access first variable in innermost frame
- **WHEN** `(lexical-ref 0 0 env)` is called with env containing frame `#(10 20 30)`
- **THEN** it SHALL return `10`

#### Scenario: Access variable in outer frame
- **WHEN** `(lexical-ref 1 2 env)` is called with env `(#(a b) #(x y z))`
- **THEN** it SHALL return `z`

### Requirement: runtime provides lexical-set! operation
The runtime SHALL provide a `lexical-set!` function that traverses `depth` frames and mutates the value at `offset` in that frame's vector.

#### Scenario: Mutate lexical variable
- **WHEN** `(lexical-set! 0 1 99 env)` is called with env containing frame `#(10 20 30)`
- **THEN** the frame SHALL become `#(10 99 30)`

### Requirement: extend-environment creates vector frames
When called from compiled code (lambda entry), `extend-environment` SHALL create a simple vector from the argument values and cons it onto the base environment.

#### Scenario: Simple parameter list
- **WHEN** `(extend-environment '(x y z) '(1 2 3) base-env)` is called
- **THEN** the new frame SHALL be a vector `#(1 2 3)`
- **AND** `(lexical-ref 0 0 result)` SHALL return `1`
- **AND** `(lexical-ref 0 2 result)` SHALL return `3`

#### Scenario: Rest parameter
- **WHEN** `(extend-environment '(a b . rest) '(1 2 3 4) base-env)` is called
- **THEN** the new frame SHALL be a vector `#(1 2 (3 4))`
- **AND** `(lexical-ref 0 2 result)` SHALL return `(3 4)`

#### Scenario: Rest-only parameter
- **WHEN** `(extend-environment 'args '(1 2 3) base-env)` is called
- **THEN** the new frame SHALL be a vector `#((1 2 3))`

### Requirement: global environment retains list-based frames
The global environment frame SHALL continue to use the existing list-based `(cons vars vals)` structure. `define-variable!` and name-based `lookup-variable-value` SHALL continue to work unchanged on the global frame.

#### Scenario: Global define still works
- **WHEN** `(define x 42)` is evaluated at the top level
- **THEN** the global frame SHALL be updated using `define-variable!`
- **AND** `(lookup-variable-value 'x *global-env*)` SHALL return `42`

### Requirement: internal defines use pre-allocated frame slots
When a lambda body contains internal `define` forms, the compiler SHALL include those names in the frame's parameter list so they receive pre-allocated vector slots. The `define` forms SHALL be compiled as `lexical-set!` to those slots.

#### Scenario: Internal define compiled as lexical-set!
- **WHEN** `(lambda () (define x 10) x)` is compiled
- **THEN** the frame SHALL have a slot for `x`
- **AND** `(define x 10)` SHALL compile as a `lexical-set!` to that slot
- **AND** the reference to `x` SHALL compile as a `lexical-ref` from that slot
