## MODIFIED Requirements

### Requirement: Port primitives work on WASM
All port primitives (IDs 60-75) SHALL have proper WASM implementations using the `$port` buffer struct, replacing current stubs.

#### Scenario: read-char and write-char round-trip
- **WHEN** characters are written to an output port and then read from the corresponding input port
- **THEN** the characters SHALL match exactly

#### Scenario: peek-char does not advance
- **WHEN** `peek-char` is called on an input port
- **THEN** the next `read-char` SHALL return the same character

#### Scenario: read-line reads until newline
- **WHEN** `read-line` is called on a port containing "hello\nworld"
- **THEN** it SHALL return "hello" and advance past the newline
