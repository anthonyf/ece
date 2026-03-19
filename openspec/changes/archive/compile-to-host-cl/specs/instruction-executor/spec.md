## MODIFIED Requirements

### Requirement: executor supports apply dispatch
The executor SHALL handle primitive procedure application and compiled procedure application. When a dual-zone compiled zone is loaded, the executor SHALL detect when PC crosses zone boundaries and return control to the outer dual-zone executor.

#### Scenario: Apply primitive procedure
- **WHEN** `proc` contains a primitive and `argl` contains arguments
- **AND** a `(perform (op apply-primitive))` instruction is executed
- **THEN** `val` SHALL contain the result of applying the primitive to the arguments

#### Scenario: Apply compiled procedure
- **WHEN** `proc` contains a compiled-procedure with an entry label
- **THEN** the executor SHALL extend `env` with the procedure's parameters and arguments
- **AND** jump to the entry label to execute the compiled body

#### Scenario: Goto register exits interpreter zone
- **WHEN** a compiled zone is loaded
- **AND** the interpreter executes `(goto (reg continue))` with a target PC in the compiled zone (< `compiled-limit`)
- **THEN** the interpreter SHALL return all register values to the dual-zone executor for dispatch to the compiled zone
