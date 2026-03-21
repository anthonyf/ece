## ADDED Requirements

### Requirement: Self-hosted compiler works on WASM
The self-hosted ECE compiler (mc-compile, mc-compile-and-go) SHALL be able to compile and execute ECE source code at runtime on the WASM host.

#### Scenario: load a .scm file
- **WHEN** `(load "file.scm")` is called on WASM (file in localStorage)
- **THEN** each expression SHALL be read, compiled, and executed

#### Scenario: REPL evaluation
- **WHEN** `(eval (read (open-input-string "(+ 1 2)")))` is called on WASM
- **THEN** the result SHALL be `3`

### Requirement: execute-from-pc enables recursive execution
The `execute-from-pc` primitive (ID 85) SHALL re-enter the executor at a given PC and space, enabling `mc-compile-and-go` to run freshly compiled code.

#### Scenario: compile and run
- **WHEN** the compiler assembles new instructions and calls execute-from-pc
- **THEN** the executor SHALL run from the new PC and return the result
