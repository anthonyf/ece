## ADDED Requirements

### Requirement: All core primitives implemented in WAT
The WASM runtime SHALL implement all primitives with IDs 0-99 from `primitives.def` (platform = core) in WAT. Each primitive SHALL be dispatched by its stable numeric ID.

#### Scenario: Arithmetic primitives
- **WHEN** `+`, `-`, `*`, `/` are called with fixnum arguments that fit in 31 bits
- **THEN** the result SHALL be computed and returned as an i31ref fixnum

#### Scenario: Arithmetic overflow to float
- **WHEN** an arithmetic operation produces a result outside i31ref range
- **THEN** the result SHALL be returned as a boxed float ($float-box)

#### Scenario: Pair primitives
- **WHEN** `cons`, `car`, `cdr`, `set-car!`, `set-cdr!` are called
- **THEN** they SHALL operate on `$pair` structs, creating or accessing mutable fields

#### Scenario: Type predicates
- **WHEN** type predicates (`null?`, `pair?`, `number?`, `string?`, `symbol?`, `boolean?`, `char?`, `vector?`, `integer?`) are called
- **THEN** they SHALL use `ref.test` to check the WasmGC type of the argument

#### Scenario: String primitives
- **WHEN** string operations (`string-length`, `string-ref`, `string-append`, `substring`, etc.) are called
- **THEN** they SHALL operate on `$string` arrays (UTF-16 i16 elements)

#### Scenario: Vector primitives
- **WHEN** vector operations (`make-vector`, `vector-ref`, `vector-set!`, `vector-length`, etc.) are called
- **THEN** they SHALL operate on `$vector` arrays

#### Scenario: Comparison primitives
- **WHEN** `eq?` is called on two values
- **THEN** it SHALL use `ref.eq` for GC references and value comparison for i31ref

### Requirement: Primitive dispatch by numeric ID
The runtime SHALL dispatch primitive calls through a function table indexed by the primitive's numeric ID from `primitives.def`.

#### Scenario: Dispatch known primitive
- **WHEN** `apply-primitive-procedure` is called with a `$primitive` struct having ID 7 (cons)
- **THEN** it SHALL call the `cons` implementation via table lookup at index 7

#### Scenario: Dispatch unknown primitive
- **WHEN** `apply-primitive-procedure` is called with an ID that has no implementation
- **THEN** it SHALL signal an error with the primitive ID

### Requirement: Variadic primitive argument handling
Primitives with arity -1 in `primitives.def` (variadic) SHALL accept their arguments as an ECE list.

#### Scenario: Variadic addition
- **WHEN** `+` is called with arguments `(1 2 3)`
- **THEN** it SHALL walk the list, accumulate the sum, and return 6

### Requirement: I/O primitives delegate to JS imports
I/O primitives (`display`, `newline`, `write`, `read-line`, etc.) SHALL delegate to imported JS functions for actual browser I/O.

#### Scenario: Display a string
- **WHEN** `display` is called with a string argument
- **THEN** it SHALL call the imported JS `io.display_string` function with the string data

#### Scenario: Display a number
- **WHEN** `display` is called with a numeric argument
- **THEN** it SHALL convert the number to a string in WAT and call the imported JS display function
