## ADDED Requirements

### Requirement: Save/restore trace for debugging
The WASM executor SHALL support a compile-time-optional trace mode that logs every save and restore operation, including the register name, value type, and current stack depth.

#### Scenario: Trace save operation
- **WHEN** a `save` instruction executes with trace enabled
- **THEN** a JS callback fires with: PC, space-id, "save", register-id, value-type, stack-depth-after

#### Scenario: Trace restore operation
- **WHEN** a `restore` instruction executes with trace enabled
- **THEN** a JS callback fires with: PC, space-id, "restore", register-id, value-type, stack-depth-after

#### Scenario: Zero cost when disabled
- **WHEN** the trace flag is not set (production build)
- **THEN** no trace callbacks are generated and no performance impact occurs

### Requirement: WASM executor matches CL executor behavior
The WASM executor SHALL produce identical register state after each save/restore sequence as the CL executor for the same compiled instructions.

#### Scenario: Serialize proper list
- **WHEN** `serialize-value` is called on `(list 1 2 3)` from prelude-compiled code
- **THEN** the WASM executor completes without crash, producing the same result as the CL executor
