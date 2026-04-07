## ADDED Requirements

### Requirement: boot-env.scm registers all primitives
`boot-env.scm` SHALL contain calls to `%register-primitive!` for every entry in `primitives.def` with platform `core` or `browser`. The primitive IDs and names SHALL be compiled into the `.ecec` as constants (not read from files at runtime).

#### Scenario: Primitives available after boot-env loads
- **WHEN** boot-env.ecec has finished executing
- **THEN** all core and browser primitives (e.g., `+`, `-`, `car`, `cdr`, `cons`, `display`, `newline`) SHALL be bound in the global environment

#### Scenario: Primitive IDs match primitives.def
- **WHEN** boot-env.ecec registers primitive `car` with ID 5
- **THEN** that ID SHALL match the entry in `primitives.def`

### Requirement: boot-env.scm registers all assembler symbols
`boot-env.scm` SHALL call `%init-asm-syms` with the total symbol count and then `%store-asm-sym` for every instruction type, register name, source type, and operation from `operations.def`. The data SHALL be compiled into the `.ecec` as constants.

#### Scenario: Assembler symbols available after boot-env loads
- **WHEN** boot-env.ecec has finished executing
- **THEN** the assembler symbol table SHALL contain all instruction types (assign, test, branch, goto, save, restore, perform), register names (val, env, proc, argl, continue, stack), source types (const, reg, label, op), and all operations from `operations.def`

### Requirement: boot-env.scm sets up continuation and error symbols
`boot-env.scm` SHALL call `%set-continuation-syms!` with `do-winds!` and `*winding-stack*`, and `%set-error-sym!` with `error`.

#### Scenario: Continuation winding works after boot-env
- **WHEN** boot-env.ecec has finished executing
- **AND** ECE code uses `dynamic-wind` or `call/cc`
- **THEN** continuation winding SHALL function correctly using the cached symbols

### Requirement: boot-env.scm creates REPL compilation space
`boot-env.scm` SHALL call `%create-repl-space!` to create a default compilation space for REPL and `eval-string` use.

#### Scenario: REPL space available after boot-env
- **WHEN** boot-env.ecec has finished executing
- **THEN** runtime compilation via `eval-string` or the REPL SHALL have a compilation space available

### Requirement: boot-env.scm uses only primitive forms
`boot-env.scm` SHALL NOT depend on macros, prelude functions, or any definitions from other bootstrap files. It SHALL use only core special forms (`define`, `begin`, `if`, `quote`, `lambda`, `set!`) and primitive procedure calls.

#### Scenario: boot-env compiles independently
- **WHEN** `compile-file` is called on boot-env.scm
- **THEN** compilation SHALL succeed without any macros or prelude definitions loaded

### Requirement: boot-env.ecec is first in bootstrap bundle
`boot-env.ecec` SHALL be the first compilation unit in `bootstrap/bootstrap.ecec`, executing before prelude.ecec and all other bootstrap units.

#### Scenario: Bootstrap order
- **WHEN** the bootstrap bundle is loaded
- **THEN** boot-env.ecec SHALL execute first
- **AND** prelude.ecec SHALL execute after boot-env.ecec
- **AND** all prelude definitions SHALL find their required primitives already bound

### Requirement: Host runtime defines boolean bindings
The host runtime (JS `buildGlobalEnv` or CL `boot-from-compiled`) SHALL define `#t` and `#f` as variables in the global environment, bound to the boolean true and false values respectively. These cannot be defined in boot-env.ecec because the ecec text format cannot distinguish `(const #t)` as a boolean value from `(const #t)` as the symbol name `#t`.

#### Scenario: Boolean variables available
- **WHEN** the host runtime has initialized the global environment
- **THEN** `#t` SHALL evaluate to boolean true
- **AND** `#f` SHALL evaluate to boolean false
