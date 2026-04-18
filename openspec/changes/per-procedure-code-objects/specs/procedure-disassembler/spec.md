## MODIFIED Requirements

### Requirement: disassemble accepts compiled procedures and symbols

ECE SHALL provide a `disassemble` procedure, exported from the `ece` package, that accepts exactly one argument: a compiled procedure value, a code-object value, or a symbol. When given a symbol, `disassemble` SHALL look up the symbol as a global binding in `*global-env*` and use the resulting value as if it had been passed directly. When given a compiled procedure, `disassemble` SHALL unwrap it to its underlying code object and disassemble that. When given a code-object directly, `disassemble` SHALL operate on it without further unwrapping. `disassemble` SHALL return an unspecified value; its effect is printing to the current output port.

#### Scenario: Disassembling a compiled procedure value prints bytecode

- **WHEN** `(define (square x) (* x x))` has been evaluated and `(disassemble square)` is called
- **THEN** output SHALL be written to the current output port
- **AND** the output SHALL include one or more instruction lines in symbolic register-machine form (e.g. `(assign ...)`, `(goto ...)`)
- **AND** `disassemble` SHALL return an unspecified value

#### Scenario: Disassembling by symbol resolves in the global environment

- **WHEN** `(define (square x) (* x x))` has been evaluated and `(disassemble 'square)` is called
- **THEN** the output SHALL be identical to `(disassemble square)` invoked on the same binding

#### Scenario: Disassembling an unbound symbol reports the missing binding

- **WHEN** no global binding for `foo` exists and `(disassemble 'foo)` is called
- **THEN** the output SHALL contain the text `no global binding` and the symbol name `foo`
- **AND** `disassemble` SHALL return without raising a condition

#### Scenario: Disassembling a code object directly

- **WHEN** `(disassemble (compile '(lambda (x) (* x x))))` is called
- **THEN** the output SHALL contain instruction lines for the lambda's bytecode
- **AND** `disassemble` SHALL NOT attempt to unwrap the code object as if it were a compiled procedure

### Requirement: disassemble output begins with a header

`disassemble` SHALL emit a header identifying the code object before any instruction lines. The header SHALL include the procedure name read from the code object's name field (or the literal `<anonymous>` if the name field is `#f`) and the code object's identity in a human-readable form.

#### Scenario: Header shows procedure name

- **WHEN** `disassemble` is called on a code object whose name field is `square`
- **THEN** the output SHALL begin with a header line containing `square`

#### Scenario: Anonymous code object shows <anonymous>

- **WHEN** `disassemble` is called on a code object whose name field is `#f`
- **THEN** the output SHALL contain `<anonymous>` in the header

#### Scenario: Compiled-zone header annotation is deferred

- **WHEN** `disassemble` is called on a code object whose `native-fn` field is non-`#f` (CL codegen / native zone)
- **THEN** this capability imposes no requirement on the header to indicate compiled-zone status
- **AND** support for emitting a host-compiled note is deferred to a future proposal

### Requirement: disassemble emits one line per instruction

For each instruction in the code object's instruction vector, `disassemble` SHALL emit a line containing the instruction's PC and its source-form s-expression. PCs SHALL be formatted as decimal integers padded for column alignment.

#### Scenario: Each instruction appears on its own line with its PC

- **WHEN** `disassemble` emits the instruction at PC 14 which has source form `(assign val (const ()))`
- **THEN** the output SHALL contain a single line where `14` appears before `(assign val (const ()))`

#### Scenario: Symbolic operation names are preserved

- **WHEN** an instruction's source form is `(test (op null?) (reg argl))`
- **THEN** the emitted line SHALL contain `null?` as a symbol name (not an opaque function reference or pipe-escaped CL symbol)

#### Scenario: Disassembly iterates the full code-object length

- **WHEN** `disassemble` is called on a code object of length N
- **THEN** the output SHALL contain exactly N instruction lines
- **AND** the PCs SHALL cover the range `0` through `N-1` in ascending order

### Requirement: %procedure-name-ref primitive exposes the code-object name field

ECE SHALL provide a `%procedure-name-ref` host primitive that returns the name stored on a code object, or `#f` if the code object's name field is `#f`. The primitive SHALL accept either a code object directly or a value from which a code object can be derived (e.g., a compiled procedure).

#### Scenario: Returns registered name for code object

- **WHEN** a code object for `(define (square x) (* x x))` exists and `(%procedure-name-ref <code-object>)` is called
- **THEN** it SHALL return `square`

#### Scenario: Returns #f when code object has no name

- **WHEN** a code object for an anonymous lambda exists and `(%procedure-name-ref <code-object>)` is called
- **THEN** it SHALL return `#f`

#### Scenario: Accepts a compiled procedure value

- **WHEN** `(define (f x) x)` is evaluated and `(%procedure-name-ref f)` is called
- **THEN** it SHALL return `f`

## REMOVED Requirements

### Requirement: disassemble uses reachability walk to bound the procedure

**Reason:** Under per-procedure code objects, each code object's instruction vector contains exactly the procedure's instructions — no other procedure's instructions are concatenated into the same vector. There is no need for a reachability walk to determine where the procedure "ends," because the code object's length IS the end. This requirement is replaced by the simpler "disassemble emits one line per instruction" requirement above, which iterates the code object's entire length directly.

**Migration:** Callers of `disassemble` see no change in output format. The internal implementation simplifies from a worklist walk to a linear iteration.

### Requirement: disassemble surfaces unreached labels inside the space

**Reason:** Unreached labels were a diagnostic for cases where reachability-walk bounds and the user's intuition disagreed within a shared space. With per-procedure code objects, every label in the code object's label table is within the procedure's instruction range, and the reachability walk no longer exists. There is no "span" where unreached labels could sit because the code object is precisely its instructions.

**Migration:** Callers see no change in normal output. The "unreached labels in span" header section is no longer emitted. If the user sees unexpected control-flow behavior, the standard disassembly output (all instructions with inline labels) provides the same information directly.
