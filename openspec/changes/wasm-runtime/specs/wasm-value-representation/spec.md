## ADDED Requirements

### Requirement: WasmGC type definitions for all ECE value kinds
The WASM runtime SHALL define a WasmGC struct or array type for each ECE value kind. All ECE values SHALL be representable as `(ref eq)` — the universal value type.

#### Scenario: Fixnum representation
- **WHEN** an ECE integer value fits in 31 bits (signed, range -1073741824 to 1073741823)
- **THEN** it SHALL be represented as an `i31ref` immediate (no heap allocation)

#### Scenario: Pair representation
- **WHEN** a cons cell is created via `cons`
- **THEN** it SHALL be a WasmGC struct with mutable `car` and `cdr` fields of type `(ref null eq)`

#### Scenario: Symbol representation
- **WHEN** a symbol is created or interned
- **THEN** it SHALL be a WasmGC struct with an integer ID field and a reference to its name string

#### Scenario: String representation
- **WHEN** a string value is created
- **THEN** it SHALL be a WasmGC array of mutable `i16` elements (UTF-16 code units)

#### Scenario: Float representation
- **WHEN** a floating-point number is created
- **THEN** it SHALL be a WasmGC struct with an `f64` field

#### Scenario: Vector representation
- **WHEN** a vector is created
- **THEN** it SHALL be a WasmGC array of mutable `(ref null eq)` elements

#### Scenario: Compiled procedure representation
- **WHEN** a compiled procedure is created (via `make-compiled-procedure`)
- **THEN** it SHALL be a WasmGC struct with `space` (i32), `pc` (i32), and `env` (ref null eq) fields

#### Scenario: Continuation representation
- **WHEN** a continuation is captured (via `call/cc`)
- **THEN** it SHALL be a WasmGC struct with `stack` and `continue` fields of type `(ref null eq)`

#### Scenario: Primitive representation
- **WHEN** a primitive procedure is referenced
- **THEN** it SHALL be a WasmGC struct with a numeric `id` field (i32) matching `primitives.def`

#### Scenario: Parameter representation
- **WHEN** an R7RS parameter object is created
- **THEN** it SHALL be a WasmGC struct with a mutable `value` field of type `(ref null eq)`

### Requirement: Singleton constants for special values
The runtime SHALL define global singleton values for #t, #f, '() (nil), eof, and void. These SHALL be the only instances of their respective types.

#### Scenario: Boolean singletons
- **WHEN** ECE code evaluates `#t` or `#f`
- **THEN** the result SHALL be the global singleton `$true` or `$false` respectively

#### Scenario: Nil singleton
- **WHEN** ECE code evaluates `'()` or an empty list
- **THEN** the result SHALL be the global singleton `$nil`

#### Scenario: EOF singleton
- **WHEN** an I/O operation reaches end of input
- **THEN** the result SHALL be the global singleton `$eof`

### Requirement: Runtime type checking via ref.test
The runtime SHALL implement type predicates (`pair?`, `number?`, `string?`, etc.) using WasmGC's `ref.test` instruction.

#### Scenario: Type predicate for pairs
- **WHEN** `pair?` is called with a cons cell
- **THEN** `ref.test (ref $pair)` SHALL return true (i32 value 1)

#### Scenario: Type predicate for fixnums
- **WHEN** `number?` is called with a fixnum
- **THEN** `ref.test i31` SHALL return true

#### Scenario: Type predicate distinguishes types
- **WHEN** `pair?` is called with a string value
- **THEN** `ref.test (ref $pair)` SHALL return false (i32 value 0)
