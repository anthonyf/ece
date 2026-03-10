## ADDED Requirements

### Requirement: read-char reads one character
`read-char` SHALL read and return one character from the given port, or from `current-input-port` if no port is given. It SHALL return the EOF sentinel when the port is exhausted.

#### Scenario: read-char from string port
- **WHEN** `(read-char (open-input-string "ab"))` is called
- **THEN** it SHALL return the character `a`

#### Scenario: read-char returns EOF at end
- **WHEN** all characters have been read from a port and `read-char` is called again
- **THEN** it SHALL return the EOF sentinel, testable with `eof?`

#### Scenario: read-char defaults to current-input-port
- **WHEN** `(read-char)` is called with no arguments
- **THEN** it SHALL read from `current-input-port`

### Requirement: peek-char looks ahead without consuming
`peek-char` SHALL return the next character from the given port without consuming it. Subsequent `read-char` calls SHALL return the same character. It SHALL return the EOF sentinel when the port is exhausted.

#### Scenario: peek-char does not consume
- **WHEN** `(peek-char (open-input-string "ab"))` is called, then `(read-char p)` is called on the same port
- **THEN** both calls SHALL return the character `a`

#### Scenario: peek-char returns EOF at end
- **WHEN** all characters have been read and `peek-char` is called
- **THEN** it SHALL return the EOF sentinel

#### Scenario: peek-char defaults to current-input-port
- **WHEN** `(peek-char)` is called with no arguments
- **THEN** it SHALL peek from `current-input-port`

### Requirement: write-char writes one character
`write-char` SHALL write one character to the given port, or to `current-output-port` if no port is given.

#### Scenario: write-char outputs a character
- **WHEN** `(write-char #\a)` is called (or equivalent via `integer->char`)
- **THEN** the character `a` SHALL be written to the current output port

#### Scenario: write-char accepts optional port
- **WHEN** `(write-char #\a port)` is called with an output port
- **THEN** the character SHALL be written to that port

### Requirement: char-ready? tests character availability
`char-ready?` SHALL return true if a character is available for reading from the port without blocking, or if the port is at EOF.

#### Scenario: char-ready? on string port
- **WHEN** `(char-ready? (open-input-string "a"))` is called
- **THEN** it SHALL return true (string ports are always ready)
