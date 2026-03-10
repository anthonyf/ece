## ADDED Requirements

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

## MODIFIED Requirements

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
