## ADDED Requirements

### Requirement: Frame-based environment model
Environments SHALL be a chain of frames, where each frame contains a values array and a reference to the enclosing frame. This matches the SICP environment model used by the CL runtime.

#### Scenario: Empty environment
- **WHEN** the runtime starts
- **THEN** the global environment SHALL be a single frame containing all primitive bindings

### Requirement: extend-environment operation
The `extend-environment` operation SHALL create a new frame with the given values and link it to the enclosing environment.

#### Scenario: Extend with arguments
- **WHEN** `extend-environment` is called with parameter names `(x y)`, values `(1 2)`, and an enclosing env
- **THEN** a new frame SHALL be created where position 0 holds 1 and position 1 holds 2, with the enclosing env as parent

### Requirement: lexical-ref operation
The `lexical-ref` operation SHALL retrieve a value by frame depth and offset, using the compiler's lexical addressing.

#### Scenario: Access local variable
- **WHEN** `lexical-ref` is called with depth 0 and offset 2
- **THEN** it SHALL return the value at index 2 in the current (innermost) frame

#### Scenario: Access variable in enclosing scope
- **WHEN** `lexical-ref` is called with depth 2 and offset 1
- **THEN** it SHALL walk 2 frames up the chain and return the value at index 1

### Requirement: lexical-set! operation
The `lexical-set!` operation SHALL mutate a value by frame depth and offset.

#### Scenario: Set local variable
- **WHEN** `lexical-set!` is called with depth 0, offset 1, and value 42
- **THEN** the value at index 1 in the current frame SHALL be updated to 42

### Requirement: lookup-variable-value operation
The `lookup-variable-value` operation SHALL search for a variable by name, walking the frame chain. This is used for global variable access where lexical addressing is not available.

#### Scenario: Find variable in global frame
- **WHEN** `lookup-variable-value` is called for symbol `display`
- **THEN** it SHALL walk the frame chain until it finds a frame containing `display` and return its value

#### Scenario: Variable not found
- **WHEN** `lookup-variable-value` is called for an unbound symbol
- **THEN** it SHALL signal an error

### Requirement: define-variable! operation
The `define-variable!` operation SHALL add or update a binding in the first (innermost) frame of the environment.

#### Scenario: Define new variable
- **WHEN** `define-variable!` is called with symbol `x` and value 10
- **THEN** symbol `x` SHALL be bound to 10 in the innermost frame

#### Scenario: Redefine existing variable
- **WHEN** `define-variable!` is called for a symbol already bound in the innermost frame
- **THEN** the existing binding SHALL be updated to the new value

### Requirement: set-variable-value! operation
The `set-variable-value!` operation SHALL find and mutate an existing binding in the frame chain.

#### Scenario: Set existing variable
- **WHEN** `set-variable-value!` is called for a bound symbol with a new value
- **THEN** the binding SHALL be updated in the frame where it was found

#### Scenario: Set unbound variable
- **WHEN** `set-variable-value!` is called for an unbound symbol
- **THEN** it SHALL signal an error
