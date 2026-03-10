## Requirements

### Requirement: metacircular compiler compiles all expression types
The metacircular compiler (`compiler.scm`) SHALL compile all expression types that the CL compiler handles: self-evaluating, variables, quote, quasiquote, if, begin, lambda, define, set, call/cc, apply, define-macro, and procedure application.

#### Scenario: Self-evaluating expressions
- **WHEN** `(ece-compile 42 'val 'next)` is called via the metacircular compiler
- **THEN** the result SHALL be an instruction sequence containing `(assign val (const 42))`

#### Scenario: Variable references
- **WHEN** `(ece-compile 'x 'val 'next)` is called via the metacircular compiler
- **THEN** the result SHALL contain a `lookup-variable-value` operation for `x`

#### Scenario: Lambda expressions
- **WHEN** `(ece-compile '(lambda (x) x) 'val 'next)` is called
- **THEN** the result SHALL contain `make-compiled-procedure` with a labeled entry point

#### Scenario: Procedure application
- **WHEN** `(ece-compile '(+ 1 2) 'val 'next)` is called
- **THEN** the result SHALL compile operator and operands, build argl, and dispatch

### Requirement: metacircular compiler produces equivalent output to CL compiler
The metacircular compiler SHALL produce instruction sequences that, when assembled and executed, yield the same results as the CL compiler for all supported expressions.

#### Scenario: Arithmetic expression equivalence
- **WHEN** `(+ 1 2)` is compiled and executed by both compilers
- **THEN** both SHALL produce the value `3`

#### Scenario: Closure equivalence
- **WHEN** `(begin (define (make-adder n) (lambda (x) (+ n x))) ((make-adder 5) 3))` is compiled and executed by both compilers
- **THEN** both SHALL produce the value `8`

#### Scenario: Macro expansion equivalence
- **WHEN** a macro-using expression like `(cond ((= 1 1) 42))` is compiled and executed by both compilers
- **THEN** both SHALL produce the value `42`

#### Scenario: call/cc equivalence
- **WHEN** `(call/cc (lambda (k) (k 42)))` is compiled and executed by both compilers
- **THEN** both SHALL produce the value `42`

### Requirement: metacircular compile-and-go integrates compilation and execution
The metacircular compiler SHALL provide a `compile-and-go` function (named `mc-compile-and-go` to avoid shadowing) that compiles an expression, assembles it into the global instruction vector, and executes it.

#### Scenario: Compile and execute simple expression
- **WHEN** `(mc-compile-and-go '(+ 1 2))` is called
- **THEN** the expression SHALL be compiled, assembled, and executed, returning `3`

#### Scenario: Compile and execute define
- **WHEN** `(mc-compile-and-go '(define x 42))` is called followed by `(mc-compile-and-go 'x)`
- **THEN** the second call SHALL return `42`

### Requirement: instruction sequence combinators work correctly in ECE
The ECE implementations of `append-instruction-sequences`, `preserving`, `parallel-instruction-sequences`, and `tack-on-instruction-sequence` SHALL produce the same register analysis and instruction output as the CL implementations.

#### Scenario: Preserving with register conflict
- **WHEN** two sequences are combined where the first modifies `env` and the second needs `env`
- **THEN** `preserving` SHALL insert `(save env)` before and `(restore env)` after the first sequence

#### Scenario: Preserving without conflict
- **WHEN** two sequences are combined where the first modifies `val` and the second needs only `env`
- **THEN** `preserving` SHALL NOT insert any save/restore instructions

### Requirement: label generation produces unique symbols
`make-label` SHALL produce unique interned symbols using a monotonically increasing counter.

#### Scenario: Sequential labels are unique
- **WHEN** `(make-label 'test)` is called twice
- **THEN** the two labels SHALL be different symbols
