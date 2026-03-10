## Why

ECE has no character-level I/O or port abstraction. The reader is CL's `read` with a custom readtable — it can't be replaced with an ECE-native reader without `read-char`, `peek-char`, and port objects. Adding Scheme-style ports and character primitives is the foundation for a metacircular reader, source location tracking, and reducing the CL kernel.

## What Changes

- Add port objects: input ports, output ports, backed by CL streams
- Add `current-input-port` and `current-output-port` parameter procedures
- Add `open-input-file`, `open-output-file`, `close-input-port`, `close-output-port`
- Add `open-input-string` for reading from strings (needed for tests, eval-from-string)
- Add `read-char` and `peek-char` with optional port argument (default: current input port)
- Add `write-char` with optional port argument (default: current output port)
- Add `char-ready?` for non-blocking character availability check
- Add `eof-object?` for testing end-of-file on character reads (reuse existing `eof?`)
- Add character predicate primitives: `char-whitespace?`, `char-alphabetic?`, `char-numeric?`
- Add `with-input-from-file` and `with-output-to-file` for scoped port redirection
- Refactor existing `read-line` to accept an optional port argument

## Capabilities

### New Capabilities
- `ports`: Port objects, port constructors/destructors, current port parameters, scoped port redirection
- `char-io`: Character-level I/O primitives — `read-char`, `peek-char`, `write-char`, `char-ready?`
- `char-predicates`: Character classification — `char-whitespace?`, `char-alphabetic?`, `char-numeric?`

### Modified Capabilities
- `read-line`: Add optional port argument to `read-line` (currently reads from stdin only)

## Impact

- `src/runtime.lisp` — new port representation, character I/O primitives, character predicates, port management functions, updated `read-line`
- `tests/ece.lisp` — new test suites for ports, character I/O, and character predicates
- Future: enables ECE-native reader (`reader.scm`), source location tracking, smaller CL kernel
