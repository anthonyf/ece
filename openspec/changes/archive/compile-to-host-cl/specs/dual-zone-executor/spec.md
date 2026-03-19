## ADDED Requirements

### Requirement: dual-zone executor dispatches between compiled and interpreted zones
The dual-zone executor SHALL run code from two zones — a compiled zone (pre-compiled native CL) and a dynamic zone (the existing interpreter) — sharing the same registers, stack, environment, and primitives.

#### Scenario: Execution starts in compiled zone
- **WHEN** execution begins at a PC within the compiled zone range (0 to `compiled-limit`)
- **THEN** the compiled zone function SHALL execute

#### Scenario: Execution starts in dynamic zone
- **WHEN** execution begins at a PC at or above `compiled-limit`
- **THEN** the interpreter SHALL execute

#### Scenario: Transition from compiled to dynamic zone
- **WHEN** code in the compiled zone executes `(goto (reg continue))` and the target PC is ≥ `compiled-limit`
- **THEN** the compiled zone SHALL return all register values
- **AND** the outer executor SHALL pass them to the interpreter to continue execution

#### Scenario: Transition from dynamic to compiled zone
- **WHEN** code in the dynamic zone executes `(goto (reg continue))` and the target PC is < `compiled-limit`
- **THEN** the interpreter SHALL return all register values
- **AND** the outer executor SHALL pass them to the compiled zone to continue execution

### Requirement: both zones share identical machine state
The compiled zone and dynamic zone SHALL operate on the same set of registers (`val`, `env`, `proc`, `argl`, `continue`, `stack`) and produce identical results for identical instruction sequences.

#### Scenario: Register values preserved across zone transition
- **WHEN** the compiled zone sets `val` to 42 and transitions to the dynamic zone
- **THEN** the dynamic zone SHALL observe `val` as 42

#### Scenario: Stack shared across zones
- **WHEN** the compiled zone pushes a value onto `stack` and transitions to the dynamic zone
- **THEN** the dynamic zone SHALL be able to restore that value from `stack`

### Requirement: call/cc works across zone boundaries
Continuations captured by `call/cc` SHALL work correctly regardless of whether the capture site and invocation site are in different zones.

#### Scenario: Continuation captured in compiled zone, invoked from dynamic zone
- **WHEN** `call/cc` captures a continuation while executing in the compiled zone
- **AND** the continuation is invoked from code in the dynamic zone
- **THEN** execution SHALL resume at the correct PC in the compiled zone with the correct register state

#### Scenario: Continuation captured in dynamic zone, invoked from compiled zone
- **WHEN** `call/cc` captures a continuation while executing in the dynamic zone
- **AND** the continuation is invoked from code in the compiled zone
- **THEN** execution SHALL resume at the correct PC in the dynamic zone with the correct register state

### Requirement: function redefinition from REPL supersedes compiled version
When a function is redefined at the REPL (dynamic zone), the new definition SHALL take effect for all subsequent calls, even from compiled zone code.

#### Scenario: Redefine compiled function from REPL
- **WHEN** function `foo` was pre-compiled (entry PC in compiled zone)
- **AND** the user redefines `foo` at the REPL (new entry PC in dynamic zone)
- **THEN** subsequent calls to `foo` from the compiled zone SHALL invoke the new dynamic-zone definition

### Requirement: dual-zone executor is optional
The dual-zone executor SHALL be opt-in. When no compiled zone is loaded, the system SHALL fall back to the standard interpreter with no performance penalty.

#### Scenario: No compiled zone loaded
- **WHEN** no compiled zone function has been loaded
- **THEN** `execute-instructions` SHALL behave identically to its current implementation
