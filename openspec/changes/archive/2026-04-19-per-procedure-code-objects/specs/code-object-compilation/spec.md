## ADDED Requirements

### Requirement: code-object is a first-class ECE value

ECE SHALL provide a `code-object` value type that represents a single compiled procedure's bytecode and its metadata. A code object SHALL be a runtime value distinguishable by a predicate, have per-procedure instructions and label table, and carry metadata accessible to ECE code. Code objects SHALL be reachable by the garbage collector through normal value references (i.e., a code object becomes eligible for collection when no live value references it).

#### Scenario: code-object? predicate

- **WHEN** `(code-object? x)` is called on a code object produced by `(compile expr)`
- **THEN** it SHALL return `#t`
- **AND** `(code-object? x)` SHALL return `#f` for any non-code-object value (numbers, strings, pairs, compiled procedures, continuations, primitives)

#### Scenario: code objects carry instructions

- **WHEN** `(code-object-length obj)` is called on a code object for `(lambda (x) (* x x))`
- **THEN** it SHALL return a positive integer equal to the number of bytecode instructions in the procedure

#### Scenario: code objects carry a label table

- **WHEN** a code object compiled from an `if`-containing lambda is queried via `(code-object-label-entries obj)`
- **THEN** the result SHALL be a list of `(label-name . local-pc)` pairs local to that code object
- **AND** label names SHALL be local to the code object (no collision with labels in other code objects)

#### Scenario: code objects have eq? identity

- **WHEN** the same source lambda is compiled twice by separate calls to `(compile expr)`
- **THEN** each call SHALL return a distinct code object
- **AND** `(eq? obj1 obj2)` SHALL return `#f` for the two results
- **AND** `(eq? obj obj)` SHALL return `#t` for each one

### Requirement: compile is a pure function returning a code object

ECE SHALL provide a `(compile expr)` entry point that returns a fresh code object representing the compilation of `expr`. `compile` SHALL NOT mutate any global state visible to subsequent calls, and SHALL NOT append to any "current space" or shared instruction vector. Compiling the same expression twice SHALL produce two distinct, independently-usable code objects.

#### Scenario: compile returns a code object

- **WHEN** `(compile '(lambda (x) (* x x)))` is called
- **THEN** the return value SHALL satisfy `code-object?`

#### Scenario: compile is idempotent and mutation-free

- **WHEN** `(compile '(lambda (x) (* x x)))` is called twice in succession
- **THEN** each call SHALL return a fresh code object
- **AND** no ECE-visible global state (other than possible internal gensym counters) SHALL differ between the two calls
- **AND** no value produced by a prior `compile` call SHALL be mutated by a subsequent call

#### Scenario: Nested lambdas compose bottom-up

- **WHEN** `(compile '(lambda (x) (lambda (y) (cons x y))))` is called
- **THEN** the returned code object SHALL reference a distinct inner code object as a constant operand of its `make-compiled-procedure` instruction
- **AND** the inner code object SHALL itself be a fully-formed, independently-executable code object

### Requirement: Compiled procedures hold a direct code-object reference

A compiled procedure value SHALL have the shape `(compiled-procedure <code-object> <env>)` where `<code-object>` is a direct code-object value (not a `(space-id . local-pc)` pair) and `<env>` is an environment chain. `compiled-procedure-entry` SHALL return the code object; a new accessor `compiled-procedure-code` MAY be provided as a synonym. The environment representation SHALL remain the existing rib-chain (this change does not reshape environments).

#### Scenario: compiled-procedure-entry returns a code object

- **WHEN** `(define (f x) x)` is evaluated and `(compiled-procedure-entry f)` is called
- **THEN** the return value SHALL satisfy `code-object?`

#### Scenario: compiled-procedure-env is unchanged

- **WHEN** `(define (f x) x)` is evaluated and `(compiled-procedure-env f)` is called
- **THEN** the return value SHALL be the environment chain in effect when `f` was defined
- **AND** the environment SHALL have the same shape (rib-chain of frames) as before this change

### Requirement: Executor dispatches on code-object current-state

The register-machine executor SHALL track the currently-executing code object (not a space id), and SHALL switch to another code object when `(goto (reg <r>))` targets a value whose code object differs from the current one. Code-object switches SHALL update the executor's local state (current code object, current instructions, current label table) inline, without a central dispatcher or hash-table lookup.

#### Scenario: Same-procedure goto stays in the current code object

- **WHEN** a `(goto (label L))` instruction targets a label whose PC is within the current code object
- **THEN** the executor SHALL update only its PC register
- **AND** SHALL NOT perform any code-object switch

#### Scenario: Cross-procedure goto switches code objects inline

- **WHEN** a `(goto (reg val))` targets a value whose code object differs from the current one
- **THEN** the executor SHALL update its "current code object" state to the target code object
- **AND** SHALL update its current instructions and label table to those of the target code object
- **AND** SHALL NOT dispatch through a hash lookup keyed on space id

### Requirement: Labels are local to a code object

Labels emitted by the compiler SHALL be resolvable only within the code object that contains them. No instruction SHALL reference, by label name, a label defined in a different code object. Cross-procedure control transfers SHALL occur exclusively via the procedure-call ABI (i.e., a `goto`/`branch` to a register holding a compiled-procedure entry).

#### Scenario: Label target resolves within current code object

- **WHEN** a `(goto (label after-if))` instruction is executed inside a code object
- **THEN** the resolution SHALL consult the current code object's label table only
- **AND** the resolved PC SHALL be a local offset into the current code object's instruction vector

#### Scenario: Cross-procedure control transfer uses entry, not label

- **WHEN** procedure `outer` invokes procedure `inner`
- **THEN** the instruction sequence SHALL dispatch through `inner`'s compiled-procedure entry (a code-object reference), not through a cross-code-object label reference

### Requirement: Code-object metadata is accessible to ECE

Each code object SHALL carry at minimum the following metadata, readable via primitives: an optional procedure name (symbol or string, `#f` if unnamed), an arity description, and an optional source location string. A `native-fn` slot SHALL also be present on each code object for future compile-to-host use; its value SHALL be `#f` unless a host-compilation step has populated it.

#### Scenario: Procedure name metadata

- **WHEN** `(define (f x) x)` is evaluated and the code object is retrieved via `(compiled-procedure-entry f)`
- **THEN** `(code-object-name obj)` SHALL return `f` (the name by which the procedure was defined)

#### Scenario: Anonymous lambda has #f name

- **WHEN** `((lambda (x) x) 1)` is evaluated (and no define wraps it)
- **THEN** the inner code object's `(code-object-name obj)` SHALL return `#f`

#### Scenario: native-fn defaults to #f

- **WHEN** `(code-object-native-fn obj)` is called on any code object produced by `(compile expr)` with no host-compilation step
- **THEN** it SHALL return `#f`

### Requirement: .ecec file format is a code-object archive

A `.ecec` file SHALL contain a sequence of one or more code objects, wrapped in an archive header that identifies the format version and file name. Loading a `.ecec` SHALL register each code object as a runtime value and execute top-level initialization instructions per the archive's ordering. The file format SHALL include a version tag such that a runtime loading an older or newer format version produces a clear diagnostic rather than silent misinterpretation.

#### Scenario: Archive contains multiple code objects

- **WHEN** `(compile-system '("a.scm") "a.ecec")` is called where `a.scm` defines two lambdas
- **THEN** `a.ecec` SHALL contain an archive with at least two code-object entries
- **AND** each code-object entry SHALL carry its own instructions, labels, and metadata

#### Scenario: Loading registers code objects and runs top-level

- **WHEN** `(load "a.ecec")` is called on a file produced by `compile-system`
- **THEN** each code object in the archive SHALL become reachable as a runtime value
- **AND** top-level initialization instructions SHALL execute in archive order

#### Scenario: Format version mismatch is diagnosed

- **WHEN** a `.ecec` file produced by an incompatible prior format is loaded
- **THEN** the loader SHALL signal a clear error identifying the format version mismatch
- **AND** SHALL NOT attempt to execute the file as if it were a current-format archive
