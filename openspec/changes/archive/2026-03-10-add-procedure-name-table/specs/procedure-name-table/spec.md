## ADDED Requirements

### Requirement: compiler registers procedure names at define time
When `compile-define` (CL compiler) or `mc-compile-define` (MC compiler) compiles a `(define (name ...) ...)` form, the compiler SHALL emit a `(procedure-name <label> <name>)` pseudo-instruction that associates the lambda's entry label with the defined name.

#### Scenario: CL compiler emits procedure-name for define
- **WHEN** `(define (f x) (+ x 1))` is compiled by the CL compiler
- **THEN** the instruction sequence SHALL contain a `(procedure-name <entry-label> f)` pseudo-instruction

#### Scenario: MC compiler emits procedure-name for define
- **WHEN** `(define (f x) (+ x 1))` is compiled by the MC compiler
- **THEN** the instruction sequence SHALL contain a `(procedure-name <entry-label> f)` pseudo-instruction

#### Scenario: Variable-form define does not emit procedure-name
- **WHEN** `(define x 42)` is compiled (value is not a lambda)
- **THEN** no `procedure-name` pseudo-instruction SHALL be emitted

### Requirement: assembler populates procedure name table
`assemble-into-global` SHALL recognize `(procedure-name <label> <name>)` pseudo-instructions, resolve the label to a PC, and store the mapping in `*procedure-name-table*`. The pseudo-instruction SHALL NOT be emitted as a real instruction in the instruction vector.

#### Scenario: Pseudo-instruction populates table
- **WHEN** `assemble-into-global` processes a `(procedure-name ENTRY42 f)` pseudo-instruction and `ENTRY42` resolves to PC 1500
- **THEN** `(gethash 1500 *procedure-name-table*)` SHALL return `f`

#### Scenario: Pseudo-instruction is not in instruction vector
- **WHEN** `assemble-into-global` processes a `(procedure-name ...)` pseudo-instruction
- **THEN** the instruction vector SHALL NOT contain any `procedure-name` instruction

### Requirement: procedure name lookup by entry PC
`format-ece-proc` SHALL look up the entry PC of compiled procedures in `*procedure-name-table*` and display the procedure name when available.

#### Scenario: Named procedure displays name
- **WHEN** a compiled procedure with entry PC 1500 is formatted and `*procedure-name-table*` maps 1500 to `f`
- **THEN** `format-ece-proc` SHALL return a string containing `f`

#### Scenario: Unnamed procedure displays entry PC
- **WHEN** a compiled procedure's entry PC is not in `*procedure-name-table*`
- **THEN** `format-ece-proc` SHALL fall back to displaying the entry PC
