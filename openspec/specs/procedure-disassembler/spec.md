# procedure-disassembler Specification

## Purpose
Define the `disassemble` procedure exported by the `ece` package: the accepted inputs (compiled procedures, code objects, and symbols resolved in `*global-env*`), the printed output format (header + instructions with inline labels and branch/goto PC annotations), and the error messages for non-disassemblable inputs. `disassemble` is a runtime introspection tool for viewing a compiled procedure's register-machine bytecode.
## Requirements
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

### Requirement: disassemble includes labels at their target PCs

When any label from the code object's label table resolves to a PC in the code object's instruction vector, `disassemble` SHALL emit a label line at that PC, preceding the instruction line for that PC.

#### Scenario: Label appears inline before its target instruction

- **WHEN** label `after-if1` resolves to PC 158 and PC 158 is in the code object
- **THEN** the output SHALL contain a line of the form `(label after-if1)` immediately before the instruction line for PC 158

#### Scenario: Multiple labels at the same PC are all emitted

- **WHEN** labels `foo-entry` and `foo-start` both resolve to the same PC in the code object
- **THEN** the output SHALL contain a line for each label before that PC's instruction line

### Requirement: disassemble annotates branch and goto targets with resolved PCs

For any instruction whose source form is `(goto (label <name>))` or `(branch (label <name>))`, `disassemble` SHALL annotate the emitted line with the target PC.

#### Scenario: goto target is annotated with its PC

- **WHEN** an instruction at PC 144 has source form `(branch (label after-if1))` and `after-if1` resolves to PC 158
- **THEN** the emitted line for PC 144 SHALL include a comment marker and the target PC 158

### Requirement: disassemble reports clear errors for non-disassemblable inputs

When the input (after symbol resolution) is not a compiled procedure or code object, `disassemble` SHALL print a single descriptive line to the current output port identifying the category of the input, and SHALL return without raising a condition.

#### Scenario: Primitives are reported by name

- **WHEN** `(disassemble car)` or `(disassemble 'car)` is called where `car` is a host primitive
- **THEN** the output SHALL indicate that `car` is a host primitive with no bytecode available

#### Scenario: Continuations are reported as unsupported

- **WHEN** `(disassemble k)` is called where `k` is a continuation
- **THEN** the output SHALL indicate that continuations are not supported by `disassemble`

#### Scenario: Ordinary values are reported as not-a-procedure

- **WHEN** `(disassemble 42)` or `(disassemble "hello")` is called
- **THEN** the output SHALL indicate that the value is not a compiled procedure

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
