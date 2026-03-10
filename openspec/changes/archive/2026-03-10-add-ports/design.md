## Context

ECE's I/O currently uses implicit stdin/stdout with no port abstraction. `read-line`, `display`, `write`, `newline` all operate on CL's `*standard-input*`/`*standard-output*` directly. There's no way to read from files character-by-character or from strings. This blocks implementing an ECE-native reader.

R7RS Scheme defines ports as first-class objects for I/O. We follow that model.

## Goals / Non-Goals

**Goals:**
- Port objects wrapping CL streams (input and output, file and string)
- Character-level I/O: `read-char`, `peek-char`, `write-char`
- `current-input-port` / `current-output-port` as the defaults
- String ports for reading from strings (critical for eval-from-string, tests)
- Character predicates for the future ECE reader
- Backward compatible: existing I/O primitives continue to work

**Non-Goals:**
- Binary/byte ports — not needed for a text-based reader
- Port buffering control — CL handles this
- Custom port types or user-defined ports
- `read` / `write` taking port arguments — that's for the ECE reader change
- `call-with-port` — not needed yet, can add later

## Decisions

### Decision 1: Ports as tagged lists wrapping CL streams

**Choice**: `(input-port <cl-stream>)` and `(output-port <cl-stream>)`. String input ports use CL's `make-string-input-stream`.

**Alternatives considered**:
- Opaque CL objects passed through directly. Rejected — no way to type-check from ECE side, can't add metadata later (like filename for source locations).
- Hash tables with fields. Rejected — overkill, tagged lists are the ECE convention for structured values (compiled-procedure, continuation, primitive).

**Rationale**: Tagged lists are lightweight, match the existing ECE convention, and allow `input-port?` / `output-port?` predicates via `(eq (car x) 'input-port)`.

### Decision 2: Current ports as dynamically-scoped parameters

**Choice**: `current-input-port` and `current-output-port` are CL special variables (`*current-input-port*`, `*current-output-port*`) initialized to stdin/stdout ports. `with-input-from-file` and `with-output-to-file` dynamically rebind them.

**Alternatives considered**:
- ECE parameter objects (like `make-parameter`). Would work but adds dependency on parameterize. CL specials are simpler and faster.
- Thread-local storage. Not applicable — ECE is single-threaded.

**Rationale**: CL special variables give us dynamic scoping for free via `let` bindings on the CL side. The `with-input-from-file` primitive just wraps `(let ((*current-input-port* ...)) ...)`.

### Decision 3: Optional port argument on I/O primitives

**Choice**: `read-char`, `peek-char`, `write-char`, and `read-line` accept an optional port argument. When omitted, they use `current-input-port` or `current-output-port`.

**Rationale**: Matches R7RS. The optional argument pattern works naturally with ECE's `&rest` primitive argument handling — check if args list is empty or has one element.

### Decision 4: Reuse existing EOF sentinel

**Choice**: Character-level reads return the existing `*eof-sentinel*` on EOF, tested with the existing `eof?` primitive.

**Rationale**: No new concepts needed. `eof?` already works and is exported.

### Decision 5: Character predicates as CL-backed primitives

**Choice**: `char-whitespace?`, `char-alphabetic?`, `char-numeric?` as thin wrappers around CL's character predicates.

**Alternatives considered**:
- Implement in ECE using `char->integer` range checks. Would work but slower and more code for something CL provides directly.

**Rationale**: CL has these built in. One-line wrappers.

## Risks / Trade-offs

- **Port lifetime**: `open-input-file` returns a port that must be closed. If the user forgets `close-input-port`, the CL stream leaks. Mitigation: `with-input-from-file` handles open/close automatically — encourage its use. Full GC-based finalization is a non-goal.
- **String ports are input-only**: `open-input-string` creates a read-only port. No `open-output-string` in this change — can add later if needed.
- **Existing I/O not ported**: `display`, `write`, `newline`, `read` still use implicit CL streams, not the port abstraction. They'll be migrated when the ECE reader is built. This keeps the change focused.
