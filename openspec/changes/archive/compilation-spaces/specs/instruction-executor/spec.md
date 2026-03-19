## MODIFIED Requirements

### Requirement: executor supports control flow instructions
The executor SHALL support `test`, `branch`, `goto`, and `label` instructions for control flow. When a `goto (reg continue)` targets a PC in a different space, the executor SHALL update its local space-id, instruction array, and label table references inline — no throw/catch or dispatcher exit.

#### Scenario: Branch taken
- **WHEN** `(test (op false?) (reg val))` is executed and `val` is falsy
- **AND** the next instruction is `(branch (label L1))`
- **THEN** the program counter SHALL jump to label `L1` within the current space

#### Scenario: Goto register within same space
- **WHEN** `(goto (reg continue))` is executed
- **AND** the `continue` register contains a qualified address `(space-id . local-pc)` where `space-id` matches the current space
- **THEN** the program counter SHALL jump to `local-pc` within the current space
- **AND** no space switch SHALL occur (only a fixnum comparison)

#### Scenario: Goto register to different space
- **WHEN** `(goto (reg continue))` is executed
- **AND** the `continue` register contains a qualified address `(space-id . local-pc)` where `space-id` differs from the current space
- **THEN** the executor SHALL update its local `space-id`, `instrs`, and `ltab` variables to reference the target space
- **AND** SHALL set `pc` to `local-pc` and continue the same tagbody loop
- **AND** SHALL NOT allocate any structs, throw any tags, or call any dispatcher function

### Requirement: executor supports apply dispatch
The executor SHALL handle primitive procedure application and compiled procedure application. Compiled procedure entry points are space-qualified addresses.

#### Scenario: Apply primitive procedure
- **WHEN** `proc` contains a primitive and `argl` contains arguments
- **AND** a `(perform (op apply-primitive))` instruction is executed
- **THEN** `val` SHALL contain the result of applying the primitive to the arguments

#### Scenario: Apply compiled procedure — same space
- **WHEN** `proc` contains a compiled-procedure with a space-qualified entry `(space-id . local-pc)`
- **AND** `space-id` matches the current space
- **THEN** the executor SHALL extend `env` with the procedure's parameters and arguments
- **AND** SHALL jump to `local-pc` locally

#### Scenario: Apply compiled procedure — different space
- **WHEN** `proc` contains a compiled-procedure with a space-qualified entry `(space-id . local-pc)`
- **AND** `space-id` differs from the current space
- **THEN** the executor SHALL extend `env`, update local `space-id`/`instrs`/`ltab`, set `pc`, and continue the loop
- **AND** SHALL NOT throw or exit the executor

### Requirement: single executor loop
The executor SHALL be a single `execute-instructions` function with one `tagbody` loop. There SHALL NOT be a separate `execute-space-dispatch` function or `space-exit-request` struct. The space-id and instruction array SHALL be local variables updated inline on cross-space jumps.

#### Scenario: Repeated cross-space transitions
- **WHEN** execution bounces between multiple spaces (e.g., game code calls stdlib which calls prelude)
- **THEN** each transition SHALL update local variables (space-id, instrs, ltab) inline
- **AND** registers SHALL be preserved correctly across transitions
- **AND** no allocation or stack unwinding SHALL occur per transition
