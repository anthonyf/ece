## ADDED Requirements

### Requirement: Type predicates callable from ECE
ECE code SHALL be able to call `compiled-procedure?`, `continuation?`, and `primitive?` as regular procedures (not just internal dispatch ops).

#### Scenario: Detect compiled procedure
- **WHEN** ECE code calls `(compiled-procedure? val)` on a compiled procedure
- **THEN** it returns `#t`

#### Scenario: Detect continuation
- **WHEN** ECE code calls `(continuation? val)` on a continuation captured by call/cc
- **THEN** it returns `#t`

#### Scenario: Non-matching types return #f
- **WHEN** ECE code calls `(compiled-procedure? 42)`
- **THEN** it returns `#f`

### Requirement: Type accessors callable from ECE
ECE code SHALL be able to decompose WasmGC struct types into their component values.

#### Scenario: Extract compiled procedure entry
- **WHEN** ECE code calls `(compiled-procedure-entry proc)` on a compiled procedure
- **THEN** it returns the space-qualified entry address pair `(space-id . pc)`

#### Scenario: Extract compiled procedure env
- **WHEN** ECE code calls `(compiled-procedure-env proc)` on a compiled procedure
- **THEN** it returns the captured environment

#### Scenario: Extract continuation fields
- **WHEN** ECE code calls `(continuation-stack k)` and `(continuation-conts k)` on a continuation
- **THEN** they return the saved stack and continue-register values

### Requirement: Reconstruction primitives
ECE code SHALL be able to construct WasmGC structs from component values.

#### Scenario: Reconstruct compiled procedure
- **WHEN** ECE code calls `(%make-compiled-procedure entry env)`
- **THEN** a proper `$compiled-proc` WasmGC struct is returned (not a tagged pair)

#### Scenario: Reconstruct continuation
- **WHEN** ECE code calls `(%make-continuation stack conts)`
- **THEN** a proper `$continuation` WasmGC struct is returned
