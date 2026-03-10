## 1. Port Infrastructure

- [x] 1.1 Add port representation: `ece-make-input-port`, `ece-make-output-port` constructors, `ece-input-port-p`, `ece-output-port-p`, `ece-port-p` predicates, `ece-port-stream` accessor
- [x] 1.2 Add `*current-input-port*` and `*current-output-port*` defvars initialized to stdin/stdout ports
- [x] 1.3 Add `ece-current-input-port` and `ece-current-output-port` accessor functions

## 2. File and String Port Constructors

- [x] 2.1 Add `ece-open-input-file` and `ece-open-output-file` — open CL streams, wrap in port objects
- [x] 2.2 Add `ece-close-input-port` and `ece-close-output-port` — close the underlying CL stream
- [x] 2.3 Add `ece-open-input-string` — create input port from `make-string-input-stream`

## 3. Character I/O Primitives

- [x] 3.1 Add `ece-read-char` — read one character from port (optional arg, default current-input-port), return EOF sentinel on end
- [x] 3.2 Add `ece-peek-char` — peek one character from port (optional arg, default current-input-port), return EOF sentinel on end
- [x] 3.3 Add `ece-write-char` — write one character to port (optional arg, default current-output-port)
- [x] 3.4 Add `ece-char-ready-p` — check if character available without blocking

## 4. Character Predicates

- [x] 4.1 Add `ece-char-whitespace-p`, `ece-char-alphabetic-p`, `ece-char-numeric-p` — thin wrappers around CL character predicates

## 5. Scoped Port Redirection

- [x] 5.1 Add `ece-with-input-from-file` — open file, dynamically bind `*current-input-port*`, call thunk, close, restore
- [x] 5.2 Add `ece-with-output-to-file` — same for output

## 6. Update Existing Primitives

- [x] 6.1 Update `ece-read-line` to accept optional port argument (default current-input-port), return EOF sentinel at end

## 7. Primitive Registration & Exports

- [x] 7.1 Register all new primitives in `*wrapper-primitives*` and add exports to defpackage

## 8. Tests

- [x] 8.1 Test port predicates: `input-port?`, `output-port?`, `port?` on ports and non-ports
- [x] 8.2 Test string port: `open-input-string`, read characters, verify EOF
- [x] 8.3 Test `read-char` and `peek-char`: sequential reads, peek-then-read, EOF behavior
- [x] 8.4 Test `write-char`: write to output and verify
- [x] 8.5 Test character predicates: whitespace, alphabetic, numeric on representative characters
- [x] 8.6 Test `read-line` with port argument: read lines from string port
- [x] 8.7 Test `current-input-port` and `current-output-port` return valid ports
- [x] 8.8 Test `with-input-from-file`: read from file via scoped redirection
- [x] 8.9 Test file ports: open, read, close cycle
