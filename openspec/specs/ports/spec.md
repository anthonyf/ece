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
`current-input-port` SHALL be a parameter object (as produced by `make-parameter`) whose value is the current default input port. `current-output-port` SHALL be a parameter object whose value is the current default output port. Called with no arguments, each SHALL return the current value. Called with one argument, each SHALL set the value. Called with two arguments (a value and a flag), each SHALL set the value without invoking any converter (supporting the R7RS `parameterize` restore semantics). Initial values SHALL wrap the host's standard input and standard output streams respectively, established once at boot via the `%initial-input-port` / `%initial-output-port` primitives.

#### Scenario: current-input-port returns stdin port
- **WHEN** `(current-input-port)` is called at startup
- **THEN** the result SHALL be an input port connected to standard input

#### Scenario: current-output-port returns stdout port
- **WHEN** `(current-output-port)` is called at startup
- **THEN** the result SHALL be an output port connected to standard output

#### Scenario: current-output-port is rebindable via parameterize
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(parameterize ((current-output-port p)) (display "hi")) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hi"`
- **AND** `(current-output-port)` AFTER the parameterize SHALL equal its value BEFORE the parameterize

#### Scenario: current-output-port is a procedure (parameter object)
- **WHEN** `(procedure? current-output-port)` is evaluated
- **THEN** the result SHALL be true

### Requirement: port-parameterized write primitives
The kernel SHALL expose low-level primitives that write to an explicitly-supplied port: `%display-to-port`, `%write-to-port`, `%newline-to-port`, `%write-char-to-port`, `%write-string-to-port`. These primitives SHALL require a port argument and SHALL NOT fall back to any host stream or ambient port.

#### Scenario: %display-to-port writes to the supplied port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(%display-to-port "hello" p)` then `(get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hello"`

#### Scenario: %newline-to-port writes a newline to the supplied port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(%display-to-port "x" p) (%newline-to-port p) (%display-to-port "y" p)` is evaluated, then `(get-output-string p)`
- **THEN** the final result SHALL be `"x\ny"`

### Requirement: display/write/newline default to current-output-port
`display`, `write`, `newline`, `write-char`, `write-string` SHALL be ECE procedures that accept an optional port argument. When called with no port argument, each SHALL write to `(current-output-port)`. When called with an explicit port, each SHALL write to that port.

#### Scenario: display with no port writes to current-output-port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(parameterize ((current-output-port p)) (display "hi")) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hi"`

#### Scenario: display with explicit port writes to that port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(display "hi" p) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"hi"`

#### Scenario: write respects explicit port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(write "hi" p) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"\"hi\""` (with the string's escape-visible quotes)

#### Scenario: newline with no port writes to current-output-port
- **GIVEN** `(define p (open-output-string))`
- **WHEN** `(parameterize ((current-output-port p)) (display "x") (newline) (display "y")) (get-output-string p)` is evaluated
- **THEN** the final result SHALL be `"x\ny"`

### Requirement: scoped port redirection
`with-input-from-file` SHALL open a file, set it as the current input port for the duration of a thunk, then close it. `with-output-to-file` SHALL do the same for output.

#### Scenario: with-input-from-file redirects input
- **WHEN** a file contains "hello" and `(with-input-from-file "test.txt" (lambda () (read-char)))` is evaluated
- **THEN** `read-char` SHALL read from the file, returning the first character

#### Scenario: with-input-from-file restores port after thunk
- **WHEN** `with-input-from-file` completes (or errors)
- **THEN** `current-input-port` SHALL be restored to its previous value

#### Scenario: with-output-to-file with compiled thunk
- **WHEN** `(with-output-to-file "out.txt" (lambda () (display "hi")))` is evaluated where the lambda is a compiled procedure
- **THEN** the thunk SHALL execute successfully, writing "hi" to the file

#### Scenario: with-input-from-file with compiled thunk
- **WHEN** `(with-input-from-file "in.txt" (lambda () (read-char)))` is evaluated where the lambda is a compiled procedure
- **THEN** the thunk SHALL execute successfully, reading from the file

### Requirement: port mutator functions
The CL runtime SHALL provide mutator functions `set-ece-port-line!` and `set-ece-port-col!` for updating port tracking state. All internal code that mutates port line/column tracking SHALL use these mutators instead of raw `setf`/`cadddr` access.

#### Scenario: line tracking via mutator
- **WHEN** `ece-read-char` reads a newline character from a port
- **THEN** the port's line counter SHALL be incremented via `set-ece-port-line!`
- **AND** the port's column counter SHALL be reset to 0 via `set-ece-port-col!`

#### Scenario: column tracking via mutator
- **WHEN** `ece-read-char` reads a non-newline character from a port
- **THEN** the port's column counter SHALL be incremented via `set-ece-port-col!`
