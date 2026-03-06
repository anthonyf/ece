## ADDED Requirements

### Requirement: frame-based environment
The evaluator SHALL use a frame-based environment following SICP Section 4.1.3. An environment is a list of frames. Each frame is a cons cell of parallel variable and value lists.

#### Scenario: Environment lookup finds variables in frames
- **WHEN** looking up a variable in a multi-frame environment
- **THEN** it SHALL scan frames from innermost to outermost and return the first match

#### Scenario: Environment lookup signals error for unbound
- **WHEN** looking up a variable not in any frame
- **THEN** it SHALL signal an error

#### Scenario: Lambda application extends the environment
- **WHEN** applying a compound procedure
- **THEN** it SHALL create a new frame with the parameters bound to arguments, prepended to the procedure's captured environment

### Requirement: global environment as frame-based
The global environment `*global-env*` SHALL contain a single frame with all primitive procedure bindings, using the frame-based representation.

#### Scenario: Primitives accessible via initial environment
- **WHEN** evaluating `(+ 1 2)` with `*global-env*`
- **THEN** it SHALL return `3`

### Requirement: define binds a variable in the current frame
The evaluator SHALL support `(define <variable> <expression>)` which evaluates `<expression>` and binds `<variable>` in the first frame of the current environment using `define-variable!`.

#### Scenario: Simple value binding
- **WHEN** evaluating `(define x 42)`
- **THEN** `x` SHALL be bound to `42` in the current environment's first frame

#### Scenario: Expression value binding
- **WHEN** evaluating `(define y (+ 1 2))`
- **THEN** `y` SHALL be bound to `3`

#### Scenario: define returns the defined value
- **WHEN** evaluating `(define z 10)`
- **THEN** the result SHALL be `10`

### Requirement: define supports function shorthand
The evaluator SHALL support `(define (<name> <params>...) <body>...)` as syntactic sugar for `(define <name> (lambda (<params>...) <body>...))`.

#### Scenario: Function shorthand creates a lambda
- **WHEN** evaluating `(define (square x) (* x x))`
- **THEN** `square` SHALL be bound to a procedure and `(square 5)` SHALL return `25`

#### Scenario: Function shorthand with multiple parameters
- **WHEN** evaluating `(define (add a b) (+ a b))`
- **THEN** `(add 3 4)` SHALL return `7`

#### Scenario: Function shorthand with multi-body
- **WHEN** evaluating `(define (f x) (+ x 1) (+ x 2))`
- **THEN** `(f 10)` SHALL return `12`

### Requirement: define allows redefining existing bindings
The evaluator SHALL update the existing binding in the first frame when `define` is used with an already-bound variable.

#### Scenario: Redefine a variable
- **WHEN** evaluating `(define a 1)` followed by `(define a 2)`
- **THEN** `a` SHALL be bound to `2`

### Requirement: define enables named recursion
Definitions SHALL be visible in the body of the defined function, enabling direct recursion without self-passing. This works because the function closes over the frame in which it is defined.

#### Scenario: Recursive function
- **WHEN** evaluating `(define (countdown n) (if (= n 0) 0 (countdown (- n 1))))` followed by `(countdown 10)`
- **THEN** the result SHALL be `0`

#### Scenario: Tail-recursive function via define
- **WHEN** evaluating a deeply recursive defined function (e.g., countdown from 100000)
- **THEN** it SHALL complete without stack overflow
