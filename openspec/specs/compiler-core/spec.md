## Requirements

### Requirement: compile produces instruction sequences
`compile` SHALL accept an expression, a target register, and a linkage, and return an instruction sequence `(needs modifies instructions)`.

#### Scenario: Compile self-evaluating expression
- **WHEN** `(compile 42 'val 'next)` is called
- **THEN** the instruction list SHALL contain `(assign val (const 42))`
- **AND** needs SHALL be empty
- **AND** modifies SHALL contain `val`

#### Scenario: Compile variable reference
- **WHEN** `(compile 'x 'val 'next)` is called
- **THEN** the instruction list SHALL contain a lookup of `x` in `env` assigning to `val`
- **AND** needs SHALL contain `env`

#### Scenario: Compile quoted expression
- **WHEN** `(compile '(quote hello) 'val 'next)` is called
- **THEN** the instruction list SHALL contain `(assign val (const hello))`

#### Scenario: Compile call/cc expression
- **WHEN** `(compile '(call/cc receiver) 'val 'next)` is called
- **THEN** the instruction list SHALL capture a continuation and invoke the receiver with it
- **AND** the modifies list SHALL include all registers

### Requirement: compile handles if expressions
`compile` SHALL compile if expressions by compiling the predicate, consequent, and alternative, using a conditional branch.

#### Scenario: Compile if with tail linkage
- **WHEN** an if expression is compiled with linkage `return`
- **THEN** both consequent and alternative SHALL be compiled with linkage `return` (tail position)

#### Scenario: Compile if with next linkage
- **WHEN** an if expression is compiled with linkage `next`
- **THEN** the alternative SHALL fall through and the consequent SHALL jump past the alternative

### Requirement: compile handles lambda expressions
`compile` SHALL compile lambda by compiling the body as a separate instruction sequence and emitting an instruction that creates a compiled-procedure object capturing the current environment.

#### Scenario: Lambda body compiled separately
- **WHEN** `(lambda (x) (+ x 1))` is compiled
- **THEN** the body instructions SHALL be a separate sequence entered via a label
- **AND** the entry point SHALL set up the extended environment from parameters and arguments

### Requirement: compile handles begin sequences
`compile` SHALL compile begin by compiling each expression in sequence, with the last expression inheriting the linkage (tail position).

#### Scenario: Last expression in tail position
- **WHEN** `(begin (define x 1) (+ x 2))` is compiled with linkage `return`
- **THEN** `(+ x 2)` SHALL be compiled with linkage `return`
- **AND** `(define x 1)` SHALL be compiled with linkage `next`

### Requirement: compile handles applications
`compile` SHALL compile function applications by compiling the operator, compiling each operand, building the argument list, and emitting an apply dispatch.

#### Scenario: Application with primitive operator
- **WHEN** `(+ 1 2)` is compiled
- **THEN** the instructions SHALL evaluate the operator, evaluate both operands into argl, and dispatch to apply

#### Scenario: Application in tail position
- **WHEN** an application is compiled with linkage `return`
- **THEN** the apply dispatch SHALL use a tail-call mechanism (no save of continuation)

### Requirement: compile handles define
`compile` SHALL compile `define` by compiling the value expression, then emitting a `define-variable!` operation.

#### Scenario: Simple define
- **WHEN** `(define x 42)` is compiled
- **THEN** the instructions SHALL evaluate `42` and call `define-variable!` with `x`

#### Scenario: Function shorthand define
- **WHEN** `(define (f x) (+ x 1))` is compiled
- **THEN** it SHALL be equivalent to compiling `(define f (lambda (x) (+ x 1)))`

### Requirement: compile handles set
`compile` SHALL compile `set` by compiling the value expression, then emitting a `set-variable-value!` operation.

#### Scenario: Variable assignment
- **WHEN** `(set x 10)` is compiled
- **THEN** the instructions SHALL evaluate `10` and call `set-variable-value!` with `x`

### Requirement: compile handles quasiquote
`compile` SHALL expand quasiquote at compile time using the existing `qq-expand` function, then compile the expanded form.

#### Scenario: Quasiquote expansion
- **WHEN** `` `(a ,b c) `` is compiled
- **THEN** `qq-expand` SHALL be called at compile time and the result compiled normally

### Requirement: compile handles define-macro
`compile` SHALL process `define-macro` by storing the macro definition in the compile-time macro environment. Subsequent macro applications SHALL be expanded at compile time and the expanded form compiled.

#### Scenario: Macro defined then used
- **WHEN** `(begin (define-macro (my-if t c a) (list 'if t c a)) (my-if #t 1 2))` is compiled
- **THEN** `(my-if #t 1 2)` SHALL be expanded at compile time to `(if #t 1 2)` and compiled as an if expression

### Requirement: preserving eliminates unnecessary save/restore
The `preserving` combinator SHALL wrap save/restore around two instruction sequences only when the first sequence modifies a register that the second sequence needs.

#### Scenario: No conflict, no save
- **WHEN** seq1 modifies `val` and seq2 needs `env` (but not `val`)
- **THEN** `preserving` SHALL concatenate seq1 and seq2 without any save/restore

#### Scenario: Conflict triggers save
- **WHEN** seq1 modifies `env` and seq2 needs `env`
- **THEN** `preserving` SHALL emit `(save env)` before seq1 and `(restore env)` after seq1

### Requirement: prelude provides union function
The ECE prelude SHALL provide a `union` function that returns a list containing all elements from both input lists, without duplicates (using `eq?` comparison).

#### Scenario: Union of disjoint lists
- **WHEN** `(union '(a b) '(c d))` is called
- **THEN** the result SHALL contain `a`, `b`, `c`, `d` (in any order)

#### Scenario: Union with overlap
- **WHEN** `(union '(a b c) '(b c d))` is called
- **THEN** the result SHALL contain `a`, `b`, `c`, `d` exactly once each

#### Scenario: Union with empty list
- **WHEN** `(union '() '(a b))` is called
- **THEN** the result SHALL be `(a b)`

### Requirement: prelude provides set-difference function
The ECE prelude SHALL provide a `set-difference` function that returns elements in the first list that are not in the second list (using `eq?` comparison).

#### Scenario: Basic difference
- **WHEN** `(set-difference '(a b c d) '(b d))` is called
- **THEN** the result SHALL contain `a` and `c` but not `b` or `d`

#### Scenario: No overlap
- **WHEN** `(set-difference '(a b) '(c d))` is called
- **THEN** the result SHALL be `(a b)`

#### Scenario: Complete overlap
- **WHEN** `(set-difference '(a b) '(a b))` is called
- **THEN** the result SHALL be `()`

### Requirement: assemble-into-global is accessible as ECE primitive
The runtime SHALL expose `assemble-into-global` as an ECE primitive that takes an instruction list, appends it to the global instruction vector, registers labels, and returns the start PC.

#### Scenario: Assemble and get PC
- **WHEN** `(assemble-into-global instructions)` is called with a list of instructions
- **THEN** it SHALL return the PC at which the first instruction was placed

### Requirement: execute-from-pc is accessible as ECE primitive
The runtime SHALL expose `execute-from-pc` as an ECE primitive that executes instructions starting from a given PC using the current global state, returning the val register.

#### Scenario: Execute assembled code
- **WHEN** instructions are assembled via `assemble-into-global` returning PC, then `(execute-from-pc pc)` is called
- **THEN** it SHALL execute those instructions and return the value left in the `val` register
