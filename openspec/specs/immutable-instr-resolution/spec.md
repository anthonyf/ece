## ADDED Requirements

### Requirement: WAT reader resolves labels without mutable $instr fields
The WAT `.ecec` reader SHALL resolve all label references at instruction creation time, without mutating `$instr` struct fields after construction. The `$instr` type's `$c` and `$val` fields SHALL remain immutable.

#### Scenario: Two-phase label resolution across units
- **WHEN** an `.ecec` file contains multiple units where instructions in unit 1 reference labels defined in unit 2
- **THEN** all labels from all units are collected before any instructions are created, and each instruction is created with its label references already resolved to PC offsets

#### Scenario: Label operands in operand lists resolved at creation
- **WHEN** an instruction operand list contains a label reference (type 2)
- **THEN** the operand pair SHALL be created as `(2 . fixnum(pc))` with the resolved PC, not `(2 . label-symbol)` requiring later mutation

#### Scenario: Branch/goto/assign-label instructions resolved at creation
- **WHEN** a branch, goto-label, or assign-label instruction references a label
- **THEN** the instruction SHALL be created with `$c` set to the resolved PC and `$val` set to `$nil`, not requiring post-creation mutation

### Requirement: $continuation type recognized after WAT-loaded prelude execution
The `$continuation` struct created by `capture-continuation` SHALL pass the `continuation?` type test (`ref.test (ref $continuation)`) when dispatched from any executor context, including cross-executor resume via `call_ece_proc` from JS.

#### Scenario: Game loop yield/resume cycle
- **WHEN** a game loop calls `(yield)` which uses `call/cc`, stores the winding wrapper lambda, and JS resumes via `call_ece_proc`
- **THEN** the winding wrapper's closure correctly contains `raw-k` as a `$continuation` struct, and the `continuation?` type dispatch succeeds, allowing `(raw-k val)` to resume execution

#### Scenario: Multiple yield/resume cycles
- **WHEN** JS resumes the yield continuation and the program yields again
- **THEN** a new continuation is stored and subsequent `call_ece_proc` resumes succeed indefinitely
