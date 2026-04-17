## ADDED Requirements

### Requirement: disassemble accepts compiled procedures and symbols

ECE SHALL provide a `disassemble` procedure, exported from the `ece` package, that accepts exactly one argument: a compiled procedure value, or a symbol. When given a symbol, `disassemble` SHALL look up the symbol as a global binding in `*global-env*` and use the resulting value as if it had been passed directly. `disassemble` SHALL return an unspecified value; its effect is printing to the current output port.

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

### Requirement: disassemble output begins with a header

`disassemble` SHALL emit a header identifying the procedure before any instruction lines. The header SHALL include the procedure name (if known from `*procedure-name-table*`; otherwise the literal `<anonymous>`) and the entry address in `space:pc` form.

#### Scenario: Header shows name and entry address

- **WHEN** `disassemble` is called on a compiled procedure whose entry is `(prelude . 142)` and whose registered name is `square`
- **THEN** the output SHALL begin with a header line containing `square` and `prelude:142`

#### Scenario: Header indicates compiled-zone procedures

- **WHEN** `disassemble` is called on a compiled procedure whose space has `compiled-fn` set (CL codegen / native zone)
- **THEN** the header SHALL contain a note that the space is compiled to the host and that the instructions shown are the source form the host code was generated from

### Requirement: disassemble emits one line per reached instruction

For each instruction included by the reachability walk, `disassemble` SHALL emit a line containing the instruction's PC and its source-form s-expression (as read from `%space-source-ref`). PCs SHALL be formatted as decimal integers padded for column alignment.

#### Scenario: Each instruction appears on its own line with its PC

- **WHEN** `disassemble` emits the instruction at PC 142 which has source form `(assign val (const ()))`
- **THEN** the output SHALL contain a single line where `142` appears before `(assign val (const ()))`

#### Scenario: Symbolic operation names are preserved

- **WHEN** an instruction's source form is `(test (op null?) (reg argl))`
- **THEN** the emitted line SHALL contain `null?` as a symbol name (not an opaque function reference or pipe-escaped CL symbol)

### Requirement: disassemble includes labels at their target PCs

When any label from the space's label table resolves to a PC in the reached set, `disassemble` SHALL emit a label line at that PC, preceding the instruction line for that PC.

#### Scenario: Label appears inline before its target instruction

- **WHEN** label `after-if1` resolves to PC 158 and PC 158 is in the reached set
- **THEN** the output SHALL contain a line of the form `(label after-if1)` immediately before the instruction line for PC 158

#### Scenario: Multiple labels at the same PC are all emitted

- **WHEN** labels `foo-entry` and `foo-start` both resolve to the same PC in the reached set
- **THEN** the output SHALL contain a line for each label before that PC's instruction line

### Requirement: disassemble annotates branch and goto targets with resolved PCs

For any instruction whose source form is `(goto (label <name>))` or `(branch (label <name>))`, `disassemble` SHALL annotate the emitted line with the target PC. Targets whose resolved PC lies outside the reached set SHALL still be annotated with their PC.

#### Scenario: goto target is annotated with its PC

- **WHEN** an instruction at PC 144 has source form `(branch (label after-if1))` and `after-if1` resolves to PC 158
- **THEN** the emitted line for PC 144 SHALL include a comment marker and the target PC 158

### Requirement: disassemble uses reachability walk to bound the procedure

`disassemble` SHALL determine the set of instructions belonging to the target procedure by starting at the entry PC and following control-flow successors (fall-through from every non-`goto` instruction, plus the label target of every `goto` and `branch`) to a fixed point within the procedure's space. `disassemble` SHALL NOT emit instructions outside this reached set.

#### Scenario: Inner lambda bodies are excluded

- **WHEN** a procedure `outer` contains a nested `(lambda (x) ...)` that the compiler lifted into the same space immediately following `outer`'s body
- **AND** `disassemble` is called on `outer`
- **THEN** the output SHALL NOT include the instructions constituting the inner lambda's body
- **AND** the output SHALL end at `outer`'s last reachable instruction

#### Scenario: Walk terminates on a goto with no fall-through

- **WHEN** reachability is walking instructions and reaches a `(goto ...)`
- **THEN** the walk SHALL follow the goto's label target (if known) but SHALL NOT fall through to the PC immediately after the goto unless that PC is separately reached by a branch target or label

### Requirement: disassemble surfaces unreached labels inside the space

If the space's label table contains labels whose PCs fall within the numeric span of the reached set but which were not themselves reached, `disassemble` SHALL list these labels in the header area under a clearly marked section (e.g. "unreached labels in span"). This provides transparency when reachability and the user's intuition disagree.

#### Scenario: Unreached label in span is surfaced

- **WHEN** the reached set spans PCs 142 through 158 and the label table has `helper-retry` at PC 151 which was not reached by the walk
- **THEN** the output header SHALL list `helper-retry` under an unreached-labels section

### Requirement: disassemble reports clear errors for non-disassemblable inputs

When the input (after symbol resolution) is not a compiled procedure, `disassemble` SHALL print a single descriptive line to the current output port identifying the category of the input, and SHALL return without raising a condition.

#### Scenario: Primitives are reported by name

- **WHEN** `(disassemble car)` or `(disassemble 'car)` is called where `car` is a host primitive
- **THEN** the output SHALL indicate that `car` is a host primitive with no bytecode available

#### Scenario: Continuations are reported as unsupported

- **WHEN** `(disassemble k)` is called where `k` is a continuation
- **THEN** the output SHALL indicate that continuations are not supported by `disassemble`

#### Scenario: Ordinary values are reported as not-a-procedure

- **WHEN** `(disassemble 42)` or `(disassemble "hello")` is called
- **THEN** the output SHALL indicate that the value is not a compiled procedure

### Requirement: %procedure-name-ref primitive exposes the name table

ECE SHALL provide a `%procedure-name-ref` host primitive that returns the registered name for a PC or qualified entry `(space-id . local-pc)`, or `#f` if no name is registered. This primitive SHALL be the complement of the existing `%procedure-name-set!`.

#### Scenario: Returns registered name for qualified entry

- **WHEN** `%procedure-name-set!` has associated name `"square"` with entry `(prelude . 142)` and `(%procedure-name-ref '(prelude . 142))` is called
- **THEN** it SHALL return `"square"`

#### Scenario: Returns #f when no name is registered

- **WHEN** no name has been associated with entry `(prelude . 999)` and `(%procedure-name-ref '(prelude . 999))` is called
- **THEN** it SHALL return `#f`
