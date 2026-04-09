## ADDED Requirements

### Requirement: let compiles to inline environment extension
The compiler SHALL recognize `(let ((var init) ...) body)` as a special form and compile it directly to inline environment extension code, without macro-expanding to a lambda application.

#### Scenario: Simple let with two bindings
- **WHEN** compiling `(let ((x 1) (y 2)) (+ x y))`
- **THEN** the compiled code SHALL create one environment frame with two slots, NOT create any compiled procedure objects, and NOT perform any procedure call dispatch

#### Scenario: let parallel binding semantics
- **WHEN** compiling `(let ((x 1) (y x)) y)` where `x` is not bound in the outer scope
- **THEN** compilation SHALL fail with an unbound variable error for `x` in `y`'s init expression, because `let` bindings are not visible to each other's init expressions

#### Scenario: let parallel binding with outer shadow
- **WHEN** evaluating `(let ((x 10)) (let ((x 1) (y x)) y))`
- **THEN** the result SHALL be `10`, because the inner `let`'s init for `y` sees the outer `x`, not the inner `x`

#### Scenario: Named let falls through to macro
- **WHEN** compiling `(let loop ((n 0)) (if (< n 10) (loop (+ n 1)) n))`
- **THEN** the compiler SHALL NOT handle this as a direct let compilation; it SHALL fall through to the existing macro expansion path (letrec + lambda)

### Requirement: let* compiles to single frame with progressive scoping
The compiler SHALL recognize `(let* ((var init) ...) body)` as a special form and compile it to a single environment frame with N empty slots, filling each slot sequentially. Each init expression SHALL be compiled with only the preceding bindings visible.

#### Scenario: Simple let* with sequential reference
- **WHEN** evaluating `(let* ((x 1) (y (+ x 1))) y)`
- **THEN** the result SHALL be `2`, because `y`'s init can reference `x`

#### Scenario: let* does not allow forward references
- **WHEN** compiling `(let* ((x y) (y 42)) x)` where `y` is not bound in the outer scope
- **THEN** compilation SHALL fail with an unbound variable error for `y` in `x`'s init expression

#### Scenario: let* shadowing preserves outer binding for earlier inits
- **WHEN** evaluating `(let ((x 1)) (let* ((y x) (x 2)) y))`
- **THEN** the result SHALL be `1`, because `y`'s init sees the outer `x` (the inner `x` is not yet in scope)

#### Scenario: let* single frame allocation
- **WHEN** compiling `(let* ((a 1) (b 2) (c 3)) body)`
- **THEN** the compiled code SHALL call `extend-environment` exactly once (with 3 empty slots), not three times

#### Scenario: Empty let* body
- **WHEN** evaluating `(let* () 42)`
- **THEN** the result SHALL be `42`

### Requirement: let/let* environment restoration in non-tail position
After the body of a non-tail `let` or `let*` completes, the environment SHALL be restored to the enclosing frame using the `enclosing-environment` operation.

#### Scenario: Non-tail let restores environment
- **WHEN** evaluating `(define (foo) (let ((x 1)) x) 42)`
- **THEN** the result SHALL be `42`, confirming the environment was properly restored after the let body and subsequent expressions execute in the correct scope

#### Scenario: Nested non-tail lets
- **WHEN** evaluating `(let ((x 1)) (let ((y 2)) y) x)`
- **THEN** the result SHALL be `1`, confirming the inner let's frame is popped and `x` is accessible after

### Requirement: enclosing-environment operation
Both CL and WASM runtimes SHALL provide an `enclosing-environment` operation that returns the parent frame of a given environment frame in O(1).

#### Scenario: CL runtime enclosing-environment
- **WHEN** calling `enclosing-environment` on a CL environment frame
- **THEN** it SHALL return the `cdr` of the frame cons cell (the base-env)

#### Scenario: WASM runtime enclosing-environment
- **WHEN** calling `enclosing-environment` on a WASM `$env-frame`
- **THEN** it SHALL return the `$enclosing` field of the struct
