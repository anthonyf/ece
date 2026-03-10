## ADDED Requirements

### Requirement: port representation
Ports SHALL be represented as tagged lists: `(input-port <stream>)` for input ports and `(output-port <stream>)` for output ports, where `<stream>` is a CL stream object.

#### Scenario: Input port structure
- **WHEN** `(open-input-file "test.txt")` is called
- **THEN** it SHALL return a value of the form `(input-port <stream>)`

#### Scenario: Output port structure
- **WHEN** `(open-output-file "test.txt")` is called
- **THEN** it SHALL return a value of the form `(output-port <stream>)`

### Requirement: port type predicates
`input-port?` SHALL return true for input ports. `output-port?` SHALL return true for output ports. `port?` SHALL return true for any port.

#### Scenario: input-port? recognizes input ports
- **WHEN** `(input-port? (open-input-file "test.txt"))` is evaluated
- **THEN** the result SHALL be true

#### Scenario: output-port? recognizes output ports
- **WHEN** `(output-port? (open-output-file "test.txt"))` is evaluated
- **THEN** the result SHALL be true

#### Scenario: port? recognizes both port types
- **WHEN** `(port? (open-input-file "test.txt"))` is evaluated
- **THEN** the result SHALL be true

#### Scenario: port predicates reject non-ports
- **WHEN** `(port? 42)` is evaluated
- **THEN** the result SHALL be false

### Requirement: file port constructors and destructors
`open-input-file` SHALL open a file for reading and return an input port. `open-output-file` SHALL open a file for writing and return an output port. `close-input-port` SHALL close an input port. `close-output-port` SHALL close an output port.

#### Scenario: Open and close input file
- **WHEN** `(define p (open-input-file "test.txt"))` then `(close-input-port p)` is evaluated
- **THEN** the port SHALL be opened for reading and then closed without error

#### Scenario: Open and close output file
- **WHEN** `(define p (open-output-file "test.txt"))` then `(close-output-port p)` is evaluated
- **THEN** the port SHALL be opened for writing and then closed without error

### Requirement: string input ports
`open-input-string` SHALL create an input port that reads from a string.

#### Scenario: Read from string port
- **WHEN** `(define p (open-input-string "hello"))` is evaluated
- **THEN** `p` SHALL be an input port and reading characters from it SHALL yield the characters of "hello"

### Requirement: current port accessors
`current-input-port` SHALL return the current default input port (stdin). `current-output-port` SHALL return the current default output port (stdout).

#### Scenario: current-input-port returns stdin port
- **WHEN** `(current-input-port)` is called
- **THEN** the result SHALL be an input port connected to standard input

#### Scenario: current-output-port returns stdout port
- **WHEN** `(current-output-port)` is called
- **THEN** the result SHALL be an output port connected to standard output

### Requirement: scoped port redirection
`with-input-from-file` SHALL open a file, set it as the current input port for the duration of a thunk, then close it. `with-output-to-file` SHALL do the same for output.

#### Scenario: with-input-from-file redirects input
- **WHEN** a file contains "hello" and `(with-input-from-file "test.txt" (lambda () (read-char)))` is evaluated
- **THEN** `read-char` SHALL read from the file, returning the first character

#### Scenario: with-input-from-file restores port after thunk
- **WHEN** `with-input-from-file` completes (or errors)
- **THEN** `current-input-port` SHALL be restored to its previous value
