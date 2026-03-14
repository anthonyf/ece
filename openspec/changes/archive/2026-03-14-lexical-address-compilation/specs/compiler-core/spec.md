## MODIFIED Requirements

### Requirement: compile produces instruction sequences
`compile` SHALL accept an expression, a target register, and a linkage, and return an instruction sequence `(needs modifies instructions)`.

#### Scenario: Compile self-evaluating expression
- **WHEN** `(compile 42 'val 'next)` is called
- **THEN** the instruction list SHALL contain `(assign val (const 42))`
- **AND** needs SHALL be empty
- **AND** modifies SHALL contain `val`

#### Scenario: Compile variable reference (lexical)
- **WHEN** `(compile 'x 'val 'next)` is called and `x` is in the compile-time lexical environment at depth 0, offset 1
- **THEN** the instruction list SHALL contain `(assign val (op lexical-ref) (const 0) (const 1) (reg env))`
- **AND** needs SHALL contain `env`

#### Scenario: Compile variable reference (global)
- **WHEN** `(compile 'x 'val 'next)` is called and `x` is NOT in the compile-time lexical environment
- **THEN** the instruction list SHALL contain `(assign val (op lookup-variable-value) (const x) (reg env))`
- **AND** needs SHALL contain `env`

#### Scenario: Compile quoted expression
- **WHEN** `(compile '(quote hello) 'val 'next)` is called
- **THEN** the instruction list SHALL contain `(assign val (const hello))`

#### Scenario: Compile call/cc expression
- **WHEN** `(compile '(call/cc receiver) 'val 'next)` is called
- **THEN** the instruction list SHALL capture a continuation and invoke the receiver with it
- **AND** the modifies list SHALL include all registers

### Requirement: compile handles set
`compile` SHALL compile `set` by compiling the value expression, then emitting either a `lexical-set!` operation (if the variable has a lexical address) or a `set-variable-value!` operation (if global).

#### Scenario: Lexical variable assignment
- **WHEN** `(set x 10)` is compiled and `x` is at lexical address (0, 2)
- **THEN** the instructions SHALL emit `(perform (op lexical-set!) (const 0) (const 2) (reg val) (reg env))`

#### Scenario: Global variable assignment
- **WHEN** `(set x 10)` is compiled and `x` is NOT in the lexical environment
- **THEN** the instructions SHALL emit `(perform (op set-variable-value!) (const x) (reg val) (reg env))`

### Requirement: compile handles lambda expressions
`compile` SHALL compile lambda by compiling the body as a separate instruction sequence and emitting an instruction that creates a compiled-procedure object capturing the current environment. The lambda parameters SHALL be pushed as a new frame in the compile-time lexical environment when compiling the body.

#### Scenario: Lambda body compiled with lexical env
- **WHEN** `(lambda (x y) (+ x y))` is compiled
- **THEN** the body SHALL be compiled with compile-time lexical env extended by `(x y)`
- **AND** references to `x` and `y` in the body SHALL use `lexical-ref`

#### Scenario: Lambda body with internal defines
- **WHEN** `(lambda (x) (define y 10) (+ x y))` is compiled
- **THEN** the compile-time frame SHALL include both `x` and `y`
- **AND** the define of `y` SHALL compile as `lexical-set!`
- **AND** references to both `x` and `y` SHALL use `lexical-ref`
