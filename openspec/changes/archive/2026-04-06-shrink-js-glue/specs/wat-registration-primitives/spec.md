## ADDED Requirements

### Requirement: %register-primitive! primitive
The WASM runtime SHALL expose a primitive `%register-primitive!` that accepts a symbol and a fixnum ID, creates a primitive object for that ID, and defines it in the global environment under the given symbol name.

#### Scenario: Register a core primitive
- **WHEN** ECE boot code calls `(%register-primitive! 'car 5)`
- **THEN** the symbol `car` SHALL be bound in the global environment to `(primitive 5)`

#### Scenario: Register all core primitives
- **WHEN** boot-env.ecec executes its full primitive registration sequence
- **THEN** every `core` and `browser` platform entry in `primitives.def` SHALL be bound in the global environment

### Requirement: %init-asm-syms primitive
The WASM runtime SHALL expose a primitive `%init-asm-syms` that accepts a fixnum count and allocates the assembler symbol ID array of that size.

#### Scenario: Initialize assembler symbol table
- **WHEN** ECE boot code calls `(%init-asm-syms 44)`
- **THEN** the assembler symbol ID array SHALL be allocated with 44 slots

### Requirement: %store-asm-sym primitive
The WASM runtime SHALL expose a primitive `%store-asm-sym` that accepts a fixnum slot index and a symbol, and stores that symbol's internal ID at the given slot in the assembler symbol ID array.

#### Scenario: Store an operation symbol
- **WHEN** ECE boot code calls `(%store-asm-sym 17 'lookup-variable-value)`
- **THEN** slot 17 of the assembler symbol ID array SHALL contain the symbol ID for `lookup-variable-value`

#### Scenario: All operations registered
- **WHEN** boot-env.ecec executes its full assembler symbol registration
- **THEN** slots 0-16 SHALL contain instruction types, register names, and source types
- **AND** slots 17+ SHALL contain every operation from `operations.def` in ID order

### Requirement: %set-continuation-syms! primitive
The WASM runtime SHALL expose a primitive `%set-continuation-syms!` that accepts two symbols and caches them for continuation winding support.

#### Scenario: Cache continuation symbols
- **WHEN** ECE boot code calls `(%set-continuation-syms! 'do-winds! '*winding-stack*)`
- **THEN** the WASM runtime SHALL use those symbol IDs for continuation wind/unwind dispatch

### Requirement: %set-error-sym! primitive
The WASM runtime SHALL expose a primitive `%set-error-sym!` that accepts a symbol and caches it for primitive type-error bridging.

#### Scenario: Cache error symbol
- **WHEN** ECE boot code calls `(%set-error-sym! 'error)`
- **THEN** the WASM runtime SHALL use that symbol ID when signaling type errors from primitives

### Requirement: %create-repl-space! primitive
The WASM runtime SHALL expose a primitive `%create-repl-space!` that accepts a symbol name and a fixnum size, creates a compilation space, and sets it as the current space.

#### Scenario: Create default REPL space
- **WHEN** ECE boot code calls `(%create-repl-space! 'repl 524288)`
- **THEN** a compilation space named `repl` with capacity 524288 SHALL be created and set as current

### Requirement: CL runtime provides matching no-op primitives
The CL runtime SHALL provide implementations of `%register-primitive!`, `%init-asm-syms`, `%store-asm-sym`, `%set-continuation-syms!`, `%set-error-sym!`, and `%create-repl-space!` that are no-ops (or return void), since the CL runtime already handles these concerns via `init-primitive-dispatch-tables` and `build-global-env-from-manifest`.

#### Scenario: CL bootstrap executes boot-env.ecec without error
- **WHEN** `make bootstrap` loads boot-env.ecec on the CL runtime
- **THEN** all registration calls SHALL succeed without error
- **AND** the CL runtime's existing primitive/operation setup SHALL remain unchanged
