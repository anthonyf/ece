## ADDED Requirements

### Requirement: String ops implemented in ECE
`string-split`, `string-trim`, `string-contains?`, `string-join`, `string-downcase`, and `string-upcase` SHALL be implemented as ECE functions in `prelude.scm` using only core string primitives (`string-length`, `string-ref`, `substring`, `string-append`, `char-whitespace?`, `char->integer`, `integer->char`).

#### Scenario: string-split works identically
- **WHEN** `(string-split "a,b,c" ",")` is called
- **THEN** the result is `("a" "b" "c")`

#### Scenario: string-trim removes whitespace
- **WHEN** `(string-trim "  hello  ")` is called
- **THEN** the result is `"hello"`

#### Scenario: string-contains? finds substring
- **WHEN** `(string-contains? "hello world" "world")` is called
- **THEN** the result is `#t`

#### Scenario: string-join concatenates with separator
- **WHEN** `(string-join '("a" "b" "c") ",")` is called
- **THEN** the result is `"a,b,c"`

#### Scenario: string-downcase converts to lowercase
- **WHEN** `(string-downcase "Hello")` is called
- **THEN** the result is `"hello"`

#### Scenario: string-upcase converts to uppercase
- **WHEN** `(string-upcase "Hello")` is called
- **THEN** the result is `"HELLO"`

### Requirement: print implemented in ECE
`print` SHALL be defined as `(define (print x) (display x) (newline))` in `prelude.scm`.

#### Scenario: print displays and adds newline
- **WHEN** `(print "hello")` is called
- **THEN** `hello` followed by a newline is output

### Requirement: Canvas functions via FFI
`canvas-clear`, `canvas-set-fill-color`, `canvas-fill-rect`, `canvas-fill-circle`, `canvas-draw-text`, `canvas-width`, and `canvas-height` SHALL be implemented in `browser-lib.scm` using the JS FFI primitives.

#### Scenario: Canvas programs work unchanged
- **WHEN** the Starfield or Game Loop example is run in the sandbox
- **THEN** it renders correctly using the FFI-based canvas implementations

### Requirement: Trig and timing via FFI
`sin`, `cos`, and `wall-clock-ms` SHALL be implemented in `browser-lib.scm` using the JS FFI to call `Math.sin`, `Math.cos`, and `Date` respectively.

#### Scenario: sin/cos return correct values
- **WHEN** `(sin 0)` and `(cos 0)` are called
- **THEN** they return `0.0` and `1.0` respectively

### Requirement: No behavioral changes
All existing tests SHALL pass unchanged after the migration.

#### Scenario: Full test suites pass
- **WHEN** `make test` and `make test-wasm` are run
- **THEN** all tests pass with zero failures
