## ADDED Requirements

### Requirement: Buffer-based port struct in WAT
The WASM runtime SHALL define a `$port` WasmGC struct with buffer, position, filename, direction, and open state fields.

#### Scenario: Output port write and close
- **WHEN** `(open-output-file "test.txt")` is called, characters are written, and the port is closed
- **THEN** the buffer contents SHALL be flushed to localStorage under key `"test.txt"`

#### Scenario: Input port read
- **WHEN** `(open-input-file "test.txt")` is called after data was written
- **THEN** `read-char` SHALL return characters sequentially from the buffer loaded from localStorage

#### Scenario: String port
- **WHEN** `(open-input-string "hello")` is called
- **THEN** it SHALL return a `$port` with the string as buffer and no filename (no localStorage interaction)

### Requirement: Port type predicates
`input-port?`, `output-port?`, and `port?` SHALL correctly identify `$port` structs and their direction.

#### Scenario: Type checks
- **WHEN** a port is created with `open-input-file`
- **THEN** `(input-port? p)` SHALL return `#t` and `(output-port? p)` SHALL return `#f`

### Requirement: EOF detection on ports
When `read-char` reaches the end of an input port's buffer, it SHALL return the eof sentinel.

#### Scenario: Read past end
- **WHEN** all characters have been read from an input port
- **THEN** `(read-char port)` SHALL return eof and `(eof? (read-char port))` SHALL return `#t`
