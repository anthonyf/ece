## ADDED Requirements

### Requirement: executor supports lexical-ref operation
The instruction executor SHALL support the `lexical-ref` operation, which takes a depth (integer), offset (integer), and environment, and returns the value at that position.

#### Scenario: Assign from lexical-ref
- **WHEN** instruction `(assign val (op lexical-ref) (const 0) (const 1) (reg env))` is executed
- **AND** the innermost frame of `env` is a vector `#(10 20 30)`
- **THEN** `val` SHALL be set to `20`

#### Scenario: Lexical-ref across frames
- **WHEN** instruction `(assign val (op lexical-ref) (const 2) (const 0) (reg env))` is executed
- **AND** the environment has 3+ frames
- **THEN** `val` SHALL be set to offset 0 of the frame at depth 2

### Requirement: executor supports lexical-set! operation
The instruction executor SHALL support the `lexical-set!` operation via the `perform` instruction, which takes a depth, offset, value, and environment, and mutates the frame slot.

#### Scenario: Perform lexical-set!
- **WHEN** instruction `(perform (op lexical-set!) (const 0) (const 0) (reg val) (reg env))` is executed
- **AND** `val` is `42` and the innermost frame is a vector
- **THEN** offset 0 of the innermost frame SHALL become `42`

### Requirement: executor resolves lexical operations at assembly time
The `resolve-operations` function SHALL resolve `lexical-ref` and `lexical-set!` operation names to their function pointers, just like existing operations.

#### Scenario: Operation resolution
- **WHEN** an instruction containing `(op lexical-ref)` is assembled
- **THEN** `resolve-operations` SHALL convert it to `(op-fn #<function lexical-ref>)`
